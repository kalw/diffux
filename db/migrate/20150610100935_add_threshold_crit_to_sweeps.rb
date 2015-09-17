class AddThresholdCritToSweeps < ActiveRecord::Migration
  def change
    add_column :sweeps, :threshold_crit, :integer
  end
end
