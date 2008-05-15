require File.dirname(__FILE__) + '/../test_helper'

class LocationTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
  
  def test_should_find_map
    location = locations(:chris)
    puts location.geocode
  end
  
  def test_should_save_lng_and_lat_for_my_house
    lat = 44.797213
    lng = -91.533813
    location = Location.new(:street => "216 S. Michigan St.", :city => "Eau Claire", :postal_code => "54703", :state => "WI")
    assert location.save
    assert_equal(lat, location.lat)
    assert_equal(lng, location.lng)
  end
  
end
