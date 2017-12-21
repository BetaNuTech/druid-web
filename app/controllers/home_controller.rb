class HomeController < ApplicationController
  http_basic_authenticate_with **http_auth_credentials unless Rails.env.test?

  HTTP_AUTH=true

  def index
    @page_title = "Druid Home"
  end
end
