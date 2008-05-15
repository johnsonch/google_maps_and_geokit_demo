class LocationsController < ApplicationController
  before_filter :find_location, :only =>[:edit, :update, :destroy, :show]
  
  def index
    @locations = Location.find(:all)
    
    respond_to do |format|
      format.html ## Always put .html first
    end  
  end
  
  def show
    
  end
  
  def new
    @location = Location.new(:state => "WI")
  end  
  
  def create
    @location = Location.new(params[:location])
    if @location.save
      flash[:notice] = "New Location Created"
      redirect_to locations_url
    else  
      render :action => "new"
    end  
  end
  
  def edit
    
  end
  
  def update
    if @location.update_attributes(params[:location])
      flash[:notice] = "Location Updated"
      redirect_to locations_url
    else  
      render :action => "edit"
    end  
  end
  
  def destroy
    @location.destroy
    flash[:notice] = "Location Deleted"
    redirect_to locations_url
  end
  
  
  private
  def find_location
    @location = Location.find_by_id(params[:id])
    if @location.nil?
      flash[:notice] = "Record can't be blank"
      redirect_to locations_url
    end  
  end
end
