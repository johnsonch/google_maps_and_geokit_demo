class Location < ActiveRecord::Base
  acts_as_mappable 
  before_validation :geocode_address
  
  include GeoKit::Geocoders
  
  def geocode
    @geocode ||= GoogleGeocoder.geocode(self.address)
  end
  
  def address
    "#{self.street} #{self.city},#{self.state} #{postal_code}"
  end
  


  private
  def geocode_address
    geo=GeoKit::Geocoders::MultiGeocoder.geocode (address)
    errors.add(:address, "Could not Geocode address") if !geo.success
    self.lat, self.lng = geo.lat,geo.lng if geo.success
  end
  
end
