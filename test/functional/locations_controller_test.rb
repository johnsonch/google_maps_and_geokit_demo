require File.dirname(__FILE__) + '/../test_helper'

class LocationsControllerTest < ActionController::TestCase
  def test_should_list_locations
    get :index
    assert_response :success
    assert_template "index"
  end
  
  def test_locations_list_should_have_new_location_link
    get :index
    assert_select("a", "New")
  end
  
  def test_should_show_new_location_form
    get :new
    assert_response :success
    assert_template "new"
  end
  
  def test_should_show_edit_location_form
    get :edit, {:id => locations(:brian).id}
    assert_response :success
    assert_template "edit"
  end

  def test_should_redirect_to_locations_list_when_id_is_bad
    get :edit, {:id => 25543 }
    assert_redirected_to locations_url
  end
  
  def test_should_redirect_to_locations_after_update
    Location.any_instance.expects(:save).returns(true)
    put :update, {:id => locations(:brian).id}
    assert_redirected_to locations_url
  end
  
  def test_should_redirect_to_locations_list_after_creation
    Location.any_instance.expects(:save).returns(true)
    post :create
    assert_redirected_to locations_url
  end
  
  def test_should_redisplay_new_form_if_location_is_invalid
    Location.any_instance.expects(:save).returns(false)
    post :create
    assert_template "new"
  end
  
  def test_should_redirect_locations_list_after_delete
    delete :destroy, {:id => locations(:brian).id}
    assert_redirected_to locations_url
  end
  
  def test_should_show_location
    get :show, {:id => locations(:chris).id}
    assert_response :success
    assert_template "show"
    
    assert_select("h1", locations(:chris).name)
  end
  
end
