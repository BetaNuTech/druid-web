require 'rails_helper'

RSpec.describe PropertiesController, type: :controller do
  include_context "users"

  # This should return the minimal set of attributes required to create a valid
  # Property. As you add validations to Property, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    attributes_for(:property)
  }

  let(:invalid_attributes) {
    attributes_for(:property, name: nil)
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # PropertiesController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET #index" do
    describe "as an administrator" do
      it "returns a success response" do
        sign_in administrator
        property = Property.create! valid_attributes
        get :index, params: {}, session: valid_session
        expect(response).to be_success
      end

    end

    describe "as an operator" do
      it "returns a success response" do
        sign_in operator
        property = Property.create! valid_attributes
        get :index, params: {}, session: valid_session
        expect(response).to be_success
      end
    end


    describe "as an agent" do
      it "returns a success response" do
        sign_in agent
        property = Property.create! valid_attributes
        get :index, params: {}, session: valid_session
        expect(response).to be_success
      end
    end
  end

  describe "GET #show" do
    describe "as an operator" do
      it "returns a success response" do
        sign_in operator
        property = Property.create! valid_attributes
        get :show, params: {id: property.to_param}, session: valid_session
        expect(response).to be_success
      end
    end

    describe "as an agent" do
      it "returns a success response" do
        sign_in agent
        property = Property.create! valid_attributes
        get :show, params: {id: property.to_param}, session: valid_session
        expect(response).to be_success
      end
    end
  end

  describe "GET #new" do
    describe "as an operator" do
      it "returns a success response" do
        sign_in operator
        get :new, params: {}, session: valid_session
        expect(response).to be_success
      end
    end

    describe "as an agent" do
      it "denies access" do
        sign_in agent
        get :new, params: {}, session: valid_session
        expect(response).to be_redirect
      end
    end
  end

  describe "GET #edit" do
    describe "as an administrator" do
      it "returns a success response" do
        sign_in administrator
        property = Property.create! valid_attributes
        get :edit, params: {id: property.to_param}, session: valid_session
        expect(response).to be_success
      end
    end

    describe "as an operator" do
      it "returns a success response" do
        sign_in operator
        property = Property.create! valid_attributes
        get :edit, params: {id: property.to_param}, session: valid_session
        expect(response).to be_success
      end

      it "returns a success response" do
        sign_in operator
        property = Property.create! valid_attributes
        get :edit, params: {id: property.to_param}, session: valid_session
        expect(response).to be_success
      end
    end

    describe "as an agent" do
      it "denies access" do
        sign_in agent
        property = Property.create! valid_attributes
        get :edit, params: {id: property.to_param}, session: valid_session
        expect(response).to be_redirect
      end
    end

  end

  describe "POST #create" do

    describe "as an administrator" do
      context "with valid params" do
        it "creates a new Property" do
          sign_in administrator
          expect {
            post :create, params: {property: valid_attributes}, session: valid_session
          }.to change(Property, :count).by(1)
        end
      end
    end

    describe "as an operator" do
      context "with valid params" do
        it "creates a new Property" do
          sign_in operator
          expect {
            post :create, params: {property: valid_attributes}, session: valid_session
          }.to change(Property, :count).by(1)
        end

        it "redirects to the created property" do
          sign_in operator
          post :create, params: {property: valid_attributes}, session: valid_session
          expect(response).to redirect_to(Property.last)
        end
      end

      context "with invalid params" do
        it "returns a success response (i.e. to display the 'new' template)" do
          sign_in operator
          post :create, params: {property: invalid_attributes}, session: valid_session
          expect(response).to be_success
        end
      end
    end

    describe "as an agent" do
      context "with valid params" do
        it "creates a new Property" do
          sign_in agent
          expect {
            post :create, params: {property: valid_attributes}, session: valid_session
          }.to change(Property, :count).by(0)
        end
      end
    end

  end

  describe "PUT #update" do
    let(:new_attributes) {
      attributes_for(:property, name: 'foobar')
    }

    describe "as an operator" do
      context "with valid params" do
        it "updates the requested property" do
          sign_in operator
          property = Property.create! valid_attributes
          expect{
            put :update, params: {id: property.to_param, property: new_attributes}, session: valid_session
            property.reload
          }.to change(property, :name)
        end

        it "redirects to the property" do
          sign_in operator
          property = Property.create! valid_attributes
          put :update, params: {id: property.to_param, property: valid_attributes}, session: valid_session
          expect(response).to redirect_to(property)
        end
      end

      context "with invalid params" do
        it "returns a success response (i.e. to display the 'edit' template)" do
          sign_in operator
          property = Property.create! valid_attributes
          put :update, params: {id: property.to_param, property: invalid_attributes}, session: valid_session
          expect(response).to be_success
        end
      end
    end

    describe "as an agent" do
      context "with valid params" do
        it "does not update the property" do
          sign_in agent
          property = Property.create! valid_attributes
          expect{
            put :update, params: {id: property.to_param, property: new_attributes}, session: valid_session
            property.reload
          }.to_not change(property, :name)
        end
      end
    end
  end

  describe "DELETE #destroy" do
    describe "as an operator" do
      it "destroys the requested property" do
        sign_in operator
        property = Property.create! valid_attributes
        expect {
          delete :destroy, params: {id: property.to_param}, session: valid_session
        }.to change(Property, :count).by(-1)
      end

      it "redirects to the properties list" do
        sign_in operator
        property = Property.create! valid_attributes
        delete :destroy, params: {id: property.to_param}, session: valid_session
        expect(response).to redirect_to(properties_url)
      end
    end

    describe "as an agent" do
      it "does not destroy the record" do
        sign_in agent
        property = Property.create! valid_attributes
        expect {
          delete :destroy, params: {id: property.to_param}, session: valid_session
        }.to change(Property, :count).by(0)
      end
    end
  end

end
