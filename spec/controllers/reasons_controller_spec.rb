require 'rails_helper'

RSpec.describe ReasonsController, type: :controller do
  include_context "users"
  render_views

  let(:valid_attributes) { attributes_for(:reason) }
  let(:invalid_attributes) { {description: 'foobar'}}

  describe "GET #index"
  describe "GET #new"
  describe "POST #create"
  describe "GET #show"
  describe "GET #edit"
  describe "PUT #update"
  describe "DELETE #destroy"

end
