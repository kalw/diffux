class AddBrowserToViewports < ActiveRecord::Migration
  def change
    add_column :viewports, :browser, :string
  end
end
