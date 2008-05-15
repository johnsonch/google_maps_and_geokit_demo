class CreateLocations < ActiveRecord::Migration
  def self.up
    create_table :locations do |t|
      t.string :name
      t.string :street
      t.string :city
      t.string :zip

      t.timestamps
    end
  end

  def self.down
    drop_table :locations
  end
end
