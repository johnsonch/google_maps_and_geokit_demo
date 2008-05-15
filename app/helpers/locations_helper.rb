module LocationsHelper
  
  def marker_html(location)
    "#{location.name} <br />#{location.street} <br />#{location.city}, #{location.state} #{location.postal_code}"
  end
end
