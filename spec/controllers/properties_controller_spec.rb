require 'rails_helper'

RSpec.describe PropertiesController, type: :controller do
  include_context "users"
  render_views

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

  let(:property) { default_property }
  let(:teamrole) { create(:teamrole)}
  let(:team) {
    t = create(:team)
    #TeamUser.create(team: t, user: agent, teamrole: teamrole)
    t.reload
    t
  }

  describe "GET #index" do
    describe "as an administrator" do
      it "returns a success response" do
        sign_in administrator
        get :index, params: {}
        expect(response).to be_successful
      end

    end

    describe "as an corporate" do
      it "returns a success response" do
        sign_in corporate
        get :index, params: {}
        expect(response).to be_successful
      end
    end


    describe "as an agent" do
      it "returns a success response" do
        sign_in agent
        get :index, params: {}
        expect(response).to be_successful
      end
    end
  end

  describe "GET #show" do
    describe "as an corporate" do
      it "returns a success response" do
        sign_in corporate
        get :show, params: {id: property.to_param}
        expect(response).to be_successful
      end
    end

    describe "as an agent" do
      it "returns a success response" do
        sign_in agent
        get :show, params: {id: property.to_param}
        expect(response).to be_successful
      end
    end

    describe "when the main line is not set" do
      it "flags the missing main line" do
        property.update_columns(phone: nil)
        sign_in corporate
        get :show, params: {id: property.to_param}
        expect(response).to be_successful
        expect(response.body).to match(/incoming calls cannot be resolved to this property/)
      end
    end
  end

  describe "GET #new" do
    describe "as an corporate" do
      it "returns a success response" do
        sign_in corporate
        get :new, params: {}
        expect(response).to be_successful
      end
    end

    describe "as an agent" do
      it "denies access" do
        sign_in agent
        get :new, params: {}
        expect(response).to be_redirect
      end
    end
  end

  describe "GET #edit" do
    describe "when the main line is not set" do
      it "warns that the main line is required for call routing" do
        property.update_columns(phone: nil)
        sign_in administrator
        get :edit, params: {id: property.to_param}
        expect(response).to be_successful
        expect(response.body).to match(/Main line phone number is not set/)
        expect(response.body).to match(/Required for call routing/)
      end

      it "notes that existing tracking numbers are affected" do
        property.update_columns(phone: nil)
        create(:marketing_source, property: property, name: 'Zillow',
          phone_lead_source: create(:lead_source, slug: 'CallCenter', name: 'CallCenter2'),
          tracking_number: '5555550001')
        sign_in administrator
        get :edit, params: {id: property.to_param}
        expect(response.body).to match(/already has marketing tracking numbers/)
      end
    end

    describe "as an administrator" do
      it "returns a success response" do
        sign_in administrator
        get :edit, params: {id: property.to_param}
        expect(response).to be_successful
      end
    end

    describe "as an corporate" do
      it "returns a success response" do
        sign_in corporate
        get :edit, params: {id: property.to_param}
        expect(response).to be_successful
      end

      it "returns a success response" do
        sign_in corporate
        get :edit, params: {id: property.to_param}
        expect(response).to be_successful
      end
    end

    describe "as an agent" do
      it "denies access" do
        sign_in agent
        get :edit, params: {id: property.to_param}
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
            post :create, params: {property: valid_attributes}
          }.to change(Property, :count).by(1)
        end
      end
    end

    describe "as an corporate" do
      context "with valid params" do
        it "creates a new Property" do
          sign_in corporate
          expect {
            post :create, params: {property: valid_attributes}
          }.to change(Property, :count).by(1)
        end

        it "redirects to the created property" do
          sign_in corporate
          post :create, params: {property: valid_attributes}
          expect(response).to redirect_to(Property.last)
        end
      end

      context "with invalid params" do
        it "returns a success response (i.e. to display the 'new' template)" do
          sign_in corporate
          post :create, params: {property: invalid_attributes}
          expect(response).to be_successful
        end
      end
    end

    describe "as an agent" do
      context "with valid params" do
        it "creates a new Property" do
          sign_in agent
          expect {
            post :create, params: {property: valid_attributes}
          }.to change(Property, :count).by(0)
        end
      end
    end

  end

  describe "PUT #update" do
    let(:new_attributes) {
      attributes_for(:property, name: 'foobar')
    }

    describe "as an corporate" do
      context "with valid params" do
        it "updates the requested property" do
          sign_in corporate
          expect{
            put :update, params: {id: property.to_param, property: new_attributes}
            property.reload
          }.to change(property, :name)
        end

        it "redirects to the property" do
          sign_in corporate
          put :update, params: {id: property.to_param, property: valid_attributes}
          expect(response).to redirect_to(property)
        end
      end

      context "with invalid params" do
        it "returns a success response (i.e. to display the 'edit' template)" do
          sign_in corporate
          put :update, params: {id: property.to_param, property: invalid_attributes}
          expect(response).to be_successful
        end
      end
    end

    describe "as an agent" do
      context "with valid params" do
        it "does not update the property" do
          sign_in agent
          expect{
            put :update, params: {id: property.to_param, property: new_attributes}
            property.reload
          }.to_not change(property, :name)
        end
      end
    end
  end

  describe "DELETE #destroy" do
    describe "as an corporate" do
      it "deactivates the requested property" do
        assert(property.active)
        sign_in corporate
        property_count = Property.count
        delete :destroy, params: {id: property.to_param}
        property.reload
        expect(Property.count).to eq(property_count)
        refute(property.active)
      end

      it "redirects to the properties list" do
        property
        sign_in corporate
        delete :destroy, params: {id: property.to_param}
        expect(response).to redirect_to(properties_url)
      end
    end

    describe "as an agent" do
      it "does not destroy the record" do
        property
        sign_in agent
        expect {
          delete :destroy, params: {id: property.to_param}
        }.to change(Property, :count).by(0)
      end
    end
  end

end
