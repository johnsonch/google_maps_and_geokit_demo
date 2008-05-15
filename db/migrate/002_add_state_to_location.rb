class AddStateToLocation < ActiveRecord::Migration
  def self.up
    add_column :locations, :state, :string
  end

  def self.down
    remove_column :locations, :state
  end
end
