class ChangeZipCodeToPostalCode < ActiveRecord::Migration
  def self.up
    rename_column :locations, :zip, :postal_code
  end

  def self.down
    rename_column :locations, :postal_code, :zip
  end
end
