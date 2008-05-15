class AddLatAndLngToLocations < ActiveRecord::Migration
  def self.up
    add_column :locations, :lat, :float
    add_column :locations, :lng, :float
  end

  def self.down
    remove_column :locations, :lat
    remove_column :locations, :lng
  end
end
