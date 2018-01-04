class HomeController < ApplicationController
  #http_basic_authenticate_with **http_auth_credentials unless Rails.env.test?
  before_action :authenticate_user!, except: :index

  HTTP_AUTH=true

  def index
    @page_title = "Druid Home"
  end

  def dashboard
    @page_title = "Druid Dashboard"
  end
end
