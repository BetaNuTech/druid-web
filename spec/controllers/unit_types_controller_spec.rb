require 'rails_helper'

RSpec.describe UnitTypesController, type: :controller do
  include_context "users"
  render_views

  let(:valid_attributes) { attributes_for(:unit_type) }
  let(:invalid_attributes) {{name: nil}}

  describe "GET #index" do
    let(:property) { create(:property) }
    let(:unit_type) { create(:unit_type, property: property) }

    before(:each) do
      unit_type
    end

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        get :index
        expect(response).to be_redirect
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        get :index
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should succeed" do
        sign_in agent
        get :index
        expect(response).to be_successful
      end
    end

    describe "as an corporate" do
      it "should succeed" do
        sign_in corporate
        get :index
        expect(response).to be_successful
      end
    end

    describe "as an administrator" do
      it "should succeed" do
        sign_in administrator
        get :index
        expect(response).to be_successful
      end

      it "should succeed with a property_id param" do
        sign_in administrator
        get :index, params: {property_id: property.id}
        expect(response).to be_successful
        expect(assigns(:property)).to eq(property)
      end
    end

  end

  describe "GET #new" do
    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        get :new
        expect(response).to be_redirect
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        get :new
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should fail and redirect" do
        sign_in agent
        get :new
        expect(response).to be_redirect
      end
    end

    describe "as an corporate" do
      it "should succeed" do
        sign_in corporate
        get :new
        expect(response).to be_successful
      end
    end

    describe "as an administrator" do
      it "should succeed" do
        sign_in administrator
        get :new
        expect(response).to be_successful
      end

      it "should default to active" do
        sign_in administrator
        get :new
        assert assigns(:unit_type).active
      end
    end
  end

  describe "POST #create" do
    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        post :create, params: {unit_type: valid_attributes}
        expect(response).to be_redirect
      end

      it "should not create a UnitType" do
        expect{
          post :create, params: {unit_type: valid_attributes}
        }.to_not change{UnitType.count}
      end
    end

    describe "as a unroled user" do
      before do
        sign_in unroled_user
      end

      it "should fail and redirect" do
        post :create, params: {unit_type: valid_attributes}
        expect(response).to be_redirect
      end

      it "should not create a UnitType" do
        expect{
          post :create, params: {unit_type: valid_attributes}
        }.to_not change{UnitType.count}
      end

    end

    describe "as an agent" do
      before do
        sign_in agent
      end

      it "should fail and redirect" do
        post :create, params: {unit_type: valid_attributes}
        expect(response).to be_redirect
      end

      it "should not create a UnitType" do
        expect{
          post :create, params: {unit_type: valid_attributes}
        }.to_not change{UnitType.count}
      end
    end

    describe "as an corporate" do
      before do
        sign_in corporate
      end

      it "should create a UnitType with valid attributes" do
        expect{
          post :create, params: {unit_type: valid_attributes}
        }.to change{UnitType.count}.by(1)
        post :create, params: {unit_type: valid_attributes}
        expect(response).to be_successful
      end
    end

    describe "as an administrator" do
      before do
        sign_in administrator
      end

      it "should create a UnitType with valid attributes" do
        expect{
          post :create, params: {unit_type: valid_attributes}
        }.to change{UnitType.count}.by(1)
        post :create, params: {unit_type: valid_attributes}
        expect(response).to be_successful
      end

      it "should handle invalid attributes" do
        post :create, params: {unit_type: invalid_attributes}
        expect(response).to be_successful
        expect {
          post :create, params: {unit_type: invalid_attributes}
        }.to_not change{UnitType.count}
      end
    end
  end

  describe "GET #show" do
    let(:unit_type) { create(:unit_type, property: default_property) }

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        get :show, params: {id: unit_type.id}
        expect(response).to be_redirect
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        get :show, params: {id: unit_type.id}
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      describe "in the same property" do
        it "should succeed" do
          sign_in agent
          get :show, params: {id: unit_type.id}
          expect(response).to be_successful
        end
      end
      describe "of a different property" do
        let(:unit_type2) {create(:unit_type, property: create(:property))}
        it "should fail" do
          sign_in agent
          get :show, params: {id: unit_type2.id}
          expect(response).to be_redirect
        end
      end
    end

    describe "as an corporate" do
      it "should succeed" do
        sign_in corporate
        get :show, params: {id: unit_type.id}
        expect(response).to be_successful
      end
    end

    describe "as an administrator" do
      it "should succeed" do
        sign_in administrator
        get :show, params: {id: unit_type.id}
        expect(response).to be_successful
      end
    end
  end

  describe "GET #edit" do

    let(:unit_type) { create(:unit_type) }

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        get :edit, params: {id: unit_type.id}
        expect(response).to be_redirect
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        get :edit, params: {id: unit_type.id}
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should fail and redirect" do
        sign_in agent
        get :edit, params: {id: unit_type.id}
        expect(response).to be_redirect
      end
    end

    describe "as an corporate" do
      it "should succeed" do
        sign_in corporate
        get :edit, params: {id: unit_type.id}
        expect(response).to be_successful
      end
    end

    describe "as an administrator" do
      it "should succeed" do
        sign_in administrator
        get :edit, params: {id: unit_type.id}
        expect(response).to be_successful
      end
    end
  end

  describe "PUT #update" do
    let(:unit_type) { create(:unit_type) }
    let(:updated_attributes) { {name: 'foobar12'}}
    let(:invalid_updated_attributes) {
      # Attributes with a duplicate name
      old_unit_type = create(:unit_type)
      {name: old_unit_type.name, property_id: old_unit_type.property.id}
    }

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        expect{
          put :update, params: {id: unit_type.id, unit_type: updated_attributes}
          expect(response).to be_redirect
          unit_type.reload
        }.to_not change{unit_type.name}
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        expect{
          put :update, params: {id: unit_type.id, unit_type: updated_attributes}
          expect(response).to be_redirect
          unit_type.reload
        }.to_not change{unit_type.name}
      end
    end

    describe "as an agent" do
      it "should fail and redirect" do
        sign_in agent
        expect{
          put :update, params: {id: unit_type.id, unit_type: updated_attributes}
          expect(response).to be_redirect
          unit_type.reload
        }.to_not change{unit_type.name}
      end
    end

    describe "as an corporate" do
      it "should succeed" do
        sign_in corporate
        expect{
          put :update, params: {id: unit_type.id, unit_type: updated_attributes}
          expect(response).to be_redirect
          unit_type.reload
        }.to change{unit_type.name}
      end
    end

    describe "as an administrator" do
      before do
        unit_type
        sign_in administrator
      end

      it "should succeed" do
        expect{
          put :update, params: {id: unit_type.id, unit_type: updated_attributes}
          expect(response).to be_redirect
          unit_type.reload
        }.to change{unit_type.name}
      end

      it "should handle invalid attributes" do
        expect{
          put :update, params: {id: unit_type.id, unit_type: invalid_updated_attributes}
          unit_type.reload
        }.to_not change{unit_type.name}
      end
    end
  end

  describe "DELETE #destroy" do

    let(:unit_type) { create(:unit_type) }

    before do
      unit_type
    end

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        expect {
          delete :destroy, params: {id: unit_type.id}
          expect(response).to be_redirect
        }.to_not change{UnitType.count}
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        expect {
          delete :destroy, params: {id: unit_type.id}
          expect(response).to be_redirect
        }.to_not change{UnitType.count}
      end
    end

    describe "as an agent" do
      it "should fail and redirect" do
        sign_in agent
        expect {
          delete :destroy, params: {id: unit_type.id}
          expect(response).to be_redirect
        }.to_not change{UnitType.count}
      end
    end

    describe "as an corporate" do
      it "should succeed" do
        sign_in corporate
        expect {
          delete :destroy, params: {id: unit_type.id}
          expect(response).to be_redirect
        }.to change{UnitType.count}.by(-1)
      end
    end

    describe "as an administrator" do
      it "should succeed" do
        sign_in administrator
        expect {
          delete :destroy, params: {id: unit_type.id}
          expect(response).to be_redirect
        }.to change{UnitType.count}.by(-1)
      end
    end
  end

end
