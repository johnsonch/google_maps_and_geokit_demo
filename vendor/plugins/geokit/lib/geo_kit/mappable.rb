require 'geo_kit/defaults'

module GeoKit
  # Contains class and instance methods providing distance calcuation services.  This
  # module is meant to be mixed into classes containing lat and lng attributes where
  # distance calculation is desired.  
  # 
  # At present, two forms of distance calculations are provided:
  # 
  # * Pythagorean Theory (flat Earth) - which assumes the world is flat and loses accuracy over long distances.
  # * Haversine (sphere) - which is fairly accurate, but at a performance cost.
  # 
  # Distance units supported are :miles and :kms.
  module Mappable
    PI_DIV_RAD = 0.0174
    KMS_PER_MILE = 1.609
    EARTH_RADIUS_IN_MILES = 3963.19
    EARTH_RADIUS_IN_KMS = EARTH_RADIUS_IN_MILES * KMS_PER_MILE
    MILES_PER_LATITUDE_DEGREE = 69.1
    KMS_PER_LATITUDE_DEGREE = MILES_PER_LATITUDE_DEGREE * KMS_PER_MILE
    LATITUDE_DEGREES = EARTH_RADIUS_IN_MILES / MILES_PER_LATITUDE_DEGREE  
    
    # Mix below class methods into the includer.
    def self.included(receiver) # :nodoc:
      receiver.extend ClassMethods
    end   
    
    module ClassMethods #:nodoc:
      # Returns the distance between two points.  The from and to parameters are
      # required to have lat and lng attributes.  Valid options are:
      # :units - valid values are :miles or :kms (GeoKit::default_units is the default)
      # :formula - valid values are :flat or :sphere (GeoKit::default_formula is the default)
      def distance_between(from, to, options={})
        from=GeoKit::LatLng.normalize(from)
        to=GeoKit::LatLng.normalize(to)
        return 0.0 if from == to # fixes a "zero-distance" bug
        units = options[:units] || GeoKit::default_units
        formula = options[:formula] || GeoKit::default_formula
        case formula
        when :sphere          
          units_sphere_multiplier(units) * 
              Math.acos( Math.sin(deg2rad(from.lat)) * Math.sin(deg2rad(to.lat)) + 
              Math.cos(deg2rad(from.lat)) * Math.cos(deg2rad(to.lat)) * 
              Math.cos(deg2rad(to.lng) - deg2rad(from.lng)))   
        when :flat
          Math.sqrt((units_per_latitude_degree(units)*(from.lat-to.lat))**2 + 
              (units_per_longitude_degree(from.lat, units)*(from.lng-to.lng))**2)
        end
      end

      # Returns heading in degrees (0 is north, 90 is east, 180 is south, etc)
      # from the first point to the second point. Typicaly, the instance methods will be used 
      # instead of this method.
      def heading_between(from,to)
        from=GeoKit::LatLng.normalize(from)
        to=GeoKit::LatLng.normalize(to)

        d_lng=deg2rad(to.lng-from.lng)
        from_lat=deg2rad(from.lat)
        to_lat=deg2rad(to.lat) 
        y=Math.sin(d_lng) * Math.cos(to_lat)
        x=Math.cos(from_lat)*Math.sin(to_lat)-Math.sin(from_lat)*Math.cos(to_lat)*Math.cos(d_lng)
        heading=to_heading(Math.atan2(y,x))
      end
  
      # Given a start point, distance, and heading (in degrees), provides
      # an endpoint. Returns a LatLng instance. Typically, the instance method
      # will be used instead of this method.
      def endpoint(start,heading, distance, options={})
        units = options[:units] || GeoKit::default_units
        radius = units == :miles ? EARTH_RADIUS_IN_MILES : EARTH_RADIUS_IN_KMS
        start=GeoKit::LatLng.normalize(start)        
        lat=deg2rad(start.lat)
        lng=deg2rad(start.lng)
        heading=deg2rad(heading)
        distance=distance.to_f
        
        end_lat=Math.asin(Math.sin(lat)*Math.cos(distance/radius) +
                          Math.cos(lat)*Math.sin(distance/radius)*Math.cos(heading))

        end_lng=lng+Math.atan2(Math.sin(heading)*Math.sin(distance/radius)*Math.cos(lat),
                               Math.cos(distance/radius)-Math.sin(lat)*Math.sin(end_lat))

        LatLng.new(rad2deg(end_lat),rad2deg(end_lng))
      end

      # Returns the midpoint, given two points. Returns a LatLng. 
      # Typically, the instance method will be used instead of this method.
      # Valid option:
      #   :units - valid values are :miles or :kms (:miles is the default)
      def midpoint_between(from,to,options={})
        from=GeoKit::LatLng.normalize(from)

        units = options[:units] || GeoKit::default_units
        
        heading=from.heading_to(to)
        distance=from.distance_to(to,options)
        midpoint=from.endpoint(heading,distance/2,options)
      end
  
      # Geocodes a location using the multi geocoder.
      def geocode(location)
        res = Geocoders::MultiGeocoder.geocode(location)
        return res if res.success
        raise GeoKit::Geocoders::GeocodeError      
      end
    
      protected
    
      def deg2rad(degrees)
        degrees.to_f / 180.0 * Math::PI
      end
      
      def rad2deg(rad)
        rad.to_f * 180.0 / Math::PI 
      end
      
      def to_heading(rad)
        (rad2deg(rad)+360)%360
      end

      # Returns the multiplier used to obtain the correct distance units.
      def units_sphere_multiplier(units)
        units == :miles ? EARTH_RADIUS_IN_MILES : EARTH_RADIUS_IN_KMS
      end

      # Returns the number of units per latitude degree.
      def units_per_latitude_degree(units)
        units == :miles ? MILES_PER_LATITUDE_DEGREE : KMS_PER_LATITUDE_DEGREE
      end
    
      # Returns the number units per longitude degree.
      def units_per_longitude_degree(lat, units)
        miles_per_longitude_degree = (LATITUDE_DEGREES * Math.cos(lat * PI_DIV_RAD)).abs
        units == :miles ? miles_per_longitude_degree : miles_per_longitude_degree * KMS_PER_MILE
      end  
    end
  
    # -----------------------------------------------------------------------------------------------
    # Instance methods below here
    # -----------------------------------------------------------------------------------------------
  
    # Extracts a LatLng instance. Use with models that are acts_as_mappable
    def to_lat_lng
      return self if instance_of?(GeoKit::LatLng) || instance_of?(GeoKit::GeoLoc)
      return LatLng.new(send(self.class.lat_column_name),send(self.class.lng_column_name)) if self.class.respond_to?(:acts_as_mappable)
      return nil
    end

    # Returns the distance from another point.  The other point parameter is
    # required to have lat and lng attributes.  Valid options are:
    # :units - valid values are :miles or :kms (:miles is the default)
    # :formula - valid values are :flat or :sphere (:sphere is the default)
    def distance_to(other, options={})
      self.class.distance_between(self, other, options)
    end  
    alias distance_from distance_to

    # Returns heading in degrees (0 is north, 90 is east, 180 is south, etc)
    # to the given point. The given point can be a LatLng or a string to be Geocoded 
    def heading_to(other)
      self.class.heading_between(self,other)
    end

    # Returns heading in degrees (0 is north, 90 is east, 180 is south, etc)
    # FROM the given point. The given point can be a LatLng or a string to be Geocoded 
    def heading_from(other)
      self.class.heading_between(other,self)
    end
 
    # Returns the endpoint, given a heading (in degrees) and distance.  
    # Valid option:
    # :units - valid values are :miles or :kms (:miles is the default)
    def endpoint(heading,distance,options={})
      self.class.endpoint(self,heading,distance,options)  
    end

    # Returns the midpoint, given another point on the map.  
    # Valid option:
    # :units - valid values are :miles or :kms (:miles is the default)    
    def midpoint_to(other, options={})
      self.class.midpoint_between(self,other,options)
    end
    
  end

  class LatLng 
    include Mappable

    attr_accessor :lat, :lng

    # Accepts latitude and longitude or instantiates an empty instance
    # if lat and lng are not provided. Converted to floats if provided
    def initialize(lat=nil, lng=nil)
      lat = lat.to_f if lat && !lat.is_a?(Numeric)
      lng = lng.to_f if lng && !lng.is_a?(Numeric)
      @lat = lat
      @lng = lng
    end 

    # Latitude attribute setter; stored as a float.
    def lat=(lat)
      @lat = lat.to_f if lat
    end

    # Longitude attribute setter; stored as a float;
    def lng=(lng)
      @lng=lng.to_f if lng
    end  

    # Returns the lat and lng attributes as a comma-separated string.
    def ll
      "#{lat},#{lng}"
    end
    
    #returns a string with comma-separated lat,lng values
    def to_s
      ll
    end
  
    #returns a two-element array
    def to_a
      [lat,lng]
    end
    # Returns true if the candidate object is logically equal.  Logical equivalence
    # is true if the lat and lng attributes are the same for both objects.
    def ==(other)
      other.is_a?(LatLng) ? self.lat == other.lat && self.lng == other.lng : false
    end
    
    # A *class* method to take anything which can be inferred as a point and generate
    # a LatLng from it. You should use this anything you're not sure what the input is,
    # and want to deal with it as a LatLng if at all possible. Can take:
    #  1) two arguments (lat,lng)
    #  2) a string in the format "37.1234,-129.1234" or "37.1234 -129.1234"
    #  3) a string which can be geocoded on the fly
    #  4) an array in the format [37.1234,-129.1234]
    #  5) a LatLng or GeoLoc (which is just passed through as-is)
    #  6) anything which acts_as_mappable -- a LatLng will be extracted from it
    def self.normalize(thing,other=nil)
      # if an 'other' thing is supplied, normalize the input by creating an array of two elements
      thing=[thing,other] if other
      
      if thing.is_a?(String)
        thing.strip!
        if match=thing.match(/(\-?\d+\.?\d*)[, ] ?(\-?\d+\.?\d*)$/)
          return GeoKit::LatLng.new(match[1],match[2])
        else
          res = GeoKit::Geocoders::MultiGeocoder.geocode(thing)
          return res if res.success
          raise GeoKit::Geocoders::GeocodeError  
        end
      elsif thing.is_a?(Array) && thing.size==2
        return GeoKit::LatLng.new(thing[0],thing[1])
      elsif thing.is_a?(LatLng) # will also be true for GeoLocs
        return thing
      elsif thing.class.respond_to?(:acts_as_mappable) && thing.class.respond_to?(:distance_column_name)
        return thing.to_lat_lng
      end
      
      throw ArgumentError.new("#{thing} (#{thing.class}) cannot be normalized to a LatLng. We tried interpreting it as an array, string, Mappable, etc., but no dice.")
    end
    
  end

  # This class encapsulates the result of a geocoding call
  # It's primary purpose is to homogenize the results of multiple
  # geocoding providers. It also provides some additional functionality, such as 
  # the "full address" method for geocoders that do not provide a 
  # full address in their results (for example, Yahoo), and the "is_us" method.
  class GeoLoc < LatLng
    # Location attributes.  Full address is a concatenation of all values.  For example:
    # 100 Spear St, San Francisco, CA, 94101, US
    attr_accessor :street_address, :city, :state, :zip, :country_code, :full_address
    # Attributes set upon return from geocoding.  Success will be true for successful
    # geocode lookups.  The provider will be set to the name of the providing geocoder.
    # Finally, precision is an indicator of the accuracy of the geocoding.
    attr_accessor :success, :provider, :precision
    # Street number and street name are extracted from the street address attribute.
    attr_reader :street_number, :street_name

    # Constructor expects a hash of symbols to correspond with attributes.
    def initialize(h={})
      @street_address=h[:street_address] 
      @city=h[:city] 
      @state=h[:state] 
      @zip=h[:zip] 
      @country_code=h[:country_code] 
      @success=false
      @precision='unknown'
      super(h[:lat],h[:lng])
    end

    # Returns true if geocoded to the United States.
    def is_us?
      country_code == 'US'
    end

    # full_address is provided by google but not by yahoo. It is intended that the google
    # geocoding method will provide the full address, whereas for yahoo it will be derived
    # from the parts of the address we do have.
    def full_address
      @full_address ? @full_address : to_geocodeable_s
    end

    # Extracts the street number from the street address if the street address
    # has a value.
    def street_number
      street_address[/(\d*)/] if street_address
    end

    # Returns the street name portion of the street address.
    def street_name
       street_address[street_number.length, street_address.length].strip if street_address
    end

    # gives you all the important fields as key-value pairs
    def hash
      res={}
      [:success,:lat,:lng,:country_code,:city,:state,:zip,:street_address,:provider,:full_address,:is_us?,:ll,:precision].each { |s| res[s] = self.send(s.to_s) }
      res
    end
    alias to_hash hash

    # Sets the city after capitalizing each word within the city name.
    def city=(city)
      @city = city.titleize if city
    end

    # Sets the street address after capitalizing each word within the street address.
    def street_address=(address)
      @street_address = address.titleize if address
    end  

    # Returns a comma-delimited string consisting of the street address, city, state,
    # zip, and country code.  Only includes those attributes that are non-blank.
    def to_geocodeable_s
      a=[street_address, city, state, zip, country_code].compact
      a.delete_if { |e| !e || e == '' }
      a.join(', ')      
    end

    # Returns a string representation of the instance.
    def to_s
      "Provider: #{provider}\n Street: #{street_address}\nCity: #{city}\nState: #{state}\nZip: #{zip}\nLatitude: #{lat}\nLongitude: #{lng}\nCountry: #{country_code}\nSuccess: #{success}"
    end
  end
  
  # Bounds represents a rectangular bounds, defined by the SW and NE corners
  class Bounds
    # sw and ne are LatLng objects
    attr_accessor :sw, :ne
    
    # provide sw and ne to instantiate a new Bounds instance
    def initialize(sw,ne)
      raise ArguementError if !(sw.is_a?(GeoKit::LatLng) && ne.is_a?(GeoKit::LatLng))
      @sw,@ne=sw,ne
    end
    
    #returns the a single point which is the center of the rectangular bounds
    def center
      @sw.midpoint_to(@ne)
    end
  
    # a simple string representation:sw,ne
    def to_s
      "#{@sw.to_s},#{@ne.to_s}"   
    end
    
    # a two-element array of two-element arrays: sw,ne
    def to_a
      [@sw.to_a, @ne.to_a]
    end
    
    # Returns true if the bounds contain the passed point.
    # allows for bounds which cross the meridian
    def contains?(point)
      point=GeoKit::LatLng.normalize(point)
      res = point.lat > @sw.lat && point.lat < @ne.lat
      if crosses_meridian?
        res &= point.lng < @ne.lng || point.lng > @sw.lng
      else
        res &= point.lng < @ne.lng && point.lng > @sw.lng
      end
      res
    end
    
    # returns true if the bounds crosses the international dateline
    def crosses_meridian?
      @sw.lng > @ne.lng 
    end

    # Returns true if the candidate object is logically equal.  Logical equivalence
    # is true if the lat and lng attributes are the same for both objects.
    def ==(other)
      other.is_a?(Bounds) ? self.sw == other.sw && self.ne == other.ne : false
    end
    
    class <<self
      
      # returns an instance of bounds which completely encompases the given circle
      def from_point_and_radius(point,radius,options={})
        point=LatLng.normalize(point)
        p0=point.endpoint(0,radius,options)
        p90=point.endpoint(90,radius,options)
        p180=point.endpoint(180,radius,options)
        p270=point.endpoint(270,radius,options)
        sw=GeoKit::LatLng.new(p180.lat,p270.lng)
        ne=GeoKit::LatLng.new(p0.lat,p90.lng)
        GeoKit::Bounds.new(sw,ne)
      end
      
      # Takes two main combinations of arguements to create a bounds:
      # point,point   (this is the only one which takes two arguments
      # [point,point]
      # . . . where a point is anything LatLng#normalize can handle (which is quite a lot)
      #
      # NOTE: everything combination is assumed to pass points in the order sw, ne
      def normalize (thing,other=nil)   
        # maybe this will be simple -- an actual bounds object is passed, and we can all go home
        return thing if thing.is_a? Bounds
        
        # no? OK, if there's no "other," the thing better be a two-element array        
        thing,other=thing if !other && thing.is_a?(Array) && thing.size==2

        # Now that we're set with a thing and another thing, let LatLng do the heavy lifting.
        # Exceptions may be thrown
        Bounds.new(GeoKit::LatLng.normalize(thing),GeoKit::LatLng.normalize(other))
      end
    end
  end
end