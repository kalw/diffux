require 'connection_pool'
require 'selenium-webdriver'

# Worker that takes care of creating a snapshot image
class SnapshotterWorker < SnapshotWorker

  def initialize
    @driver_pool = ConnectionPool.new(size: 1, timeout: 5) do
      if @snapshot.viewport.browser =~ /^\w*$/
        Selenium::WebDriver.for(:"#{@snapshot.viewport.browser}")
      else
        browser_short="#{@snapshot.viewport.browser.gsub(/([^,]*).*/,'\1')}"
        browser_remote_url="#{@snapshot.viewport.browser.gsub(/[^,]*,\s?(.*)/,'\1')}"
        Selenium::WebDriver.for(:remote,  :url => "#{browser_remote_url}", :desired_capabilities => :"#{browser_short}")
      end
    end
  end

  def perform(snapshot_id)
    return unless set_snapshot snapshot_id

    FileUtil.with_tempfile do |file|
      @driver_pool.with do |driver|
        snapshotter = Diffux::Snapshotter.new(
          viewport_width: @snapshot.viewport.width,
          user_agent:     @snapshot.viewport.user_agent,
          outfile:        file,
          url:            @snapshot.url.address,
          driver:         driver,
          browser:        @snapshot.viewport.browser  
        )
        snapshot = snapshotter.take_snapshot!

        Rails.logger.info <<-EOS
          Saving snapshot of #{@snapshot.url} @ #{@snapshot.viewport} with #{@snapshot.viewport.browser}
        EOS

        save_file_to_snapshot(@snapshot, file)
        @snapshot.title = snapshot[:title]
        @snapshot.log   = snapshot[:log]
      end
    end

    @snapshot.save!
  end

  private

  def save_file_to_snapshot(snapshot, file)
    File.open(file) { |f| snapshot.image = f }
  end
end
