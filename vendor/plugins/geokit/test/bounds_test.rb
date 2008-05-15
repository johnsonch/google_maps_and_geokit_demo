$LOAD_PATH.unshift File.join('..', 'lib')
require 'geo_kit/mappable'
require 'test/unit'

class BoundsTest < Test::Unit::TestCase #:nodoc: all
  
  def setup
    # This is the area in Texas
    @sw = GeoKit::LatLng.new(32.91663,-96.982841)
    @ne = GeoKit::LatLng.new(32.96302,-96.919495)
    @bounds=GeoKit::Bounds.new(@sw,@ne) 
    @loc_a=GeoKit::LatLng.new(32.918593,-96.958444) # inside bounds    
    @loc_b=GeoKit::LatLng.new(32.914144,-96.958444) # outside bouds
    
    # this is a cross-meridan area
    @cross_meridian=GeoKit::Bounds.normalize([30,170],[40,-170])
    @inside_cm=GeoKit::LatLng.new(35,175)
    @inside_cm_2=GeoKit::LatLng.new(35,-175)
    @east_of_cm=GeoKit::LatLng.new(35,-165)
    @west_of_cm=GeoKit::LatLng.new(35,165)

  end  

  def test_equality
    assert_equal GeoKit::Bounds.new(@sw,@ne), GeoKit::Bounds.new(@sw,@ne)
  end  
  
  def test_normalize
    res=GeoKit::Bounds.normalize(@sw,@ne)
    assert_equal res,GeoKit::Bounds.new(@sw,@ne)     
    res=GeoKit::Bounds.normalize([@sw,@ne])
    assert_equal res,GeoKit::Bounds.new(@sw,@ne)
    res=GeoKit::Bounds.normalize([@sw.lat,@sw.lng],[@ne.lat,@ne.lng])
    assert_equal res,GeoKit::Bounds.new(@sw,@ne)
    res=GeoKit::Bounds.normalize([[@sw.lat,@sw.lng],[@ne.lat,@ne.lng]])
    assert_equal res,GeoKit::Bounds.new(@sw,@ne)
  end
  
  def test_point_inside_bounds
    assert @bounds.contains?(@loc_a)
  end

  def test_point_outside_bounds
    assert !@bounds.contains?(@loc_b) 
  end  

  def test_point_inside_bounds_cross_meridian
    assert @cross_meridian.contains?(@inside_cm)
    assert @cross_meridian.contains?(@inside_cm_2)
  end

  def test_point_outside_bounds_cross_meridian
    assert !@cross_meridian.contains?(@east_of_cm)
    assert !@cross_meridian.contains?(@west_of_cm)
  end    
  
  def test_center
    assert_in_delta 32.939828,@bounds.center.lat,0.00005
    assert_in_delta -96.9511763,@bounds.center.lng,0.00005
  end

  def test_center_cross_meridian
    assert_in_delta 35.41160, @cross_meridian.center.lat,0.00005
    assert_in_delta 179.38112, @cross_meridian.center.lng,0.00005
  end  
  
  def test_creation_from_circle
    bounds=GeoKit::Bounds.from_point_and_radius([32.939829, -96.951176],2.5)
    inside=GeoKit::LatLng.new 32.9695270000,-96.9901590000
    outside=GeoKit::LatLng.new 32.8951550000,-96.9584440000
    assert bounds.contains?(inside)
    assert !bounds.contains?(outside)
  end
  
end