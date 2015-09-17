class AddThresholdWarnToSweeps < ActiveRecord::Migration
  def change
    add_column :sweeps, :threshold_warn, :integer
  end
end
