require 'rails_helper'

RSpec.describe UnitsController, type: :controller do
  include_context "users"
  render_views

  let(:valid_attributes) { build(:unit).attributes }
  let(:invalid_attributes) { {description: 'foobar'}}

  describe "GET #index" do
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
    end

    describe "with a property" do
      it "should only return associated units" do
        sign_in administrator
        Unit.destroy_all
        property1 = create(:property)
        unit1 = create(:unit, property: property1)
        unit2 = create(:unit, property: property1)
        unit3 = create(:unit)
        property2 = unit3.property
        get :index, params: {property_id: property1.id}
        expect(assigns(:property)).to eq(property1)
        expect(assigns(:units).count).to eq(2)
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
    end
  end

  describe "POST #create" do
    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        post :create, params: {unit: valid_attributes}
        expect(response).to be_redirect
      end

      it "should not create a Unit" do
        expect{
          post :create, params: {unit: valid_attributes}
        }.to_not change{Unit.count}
      end
    end

    describe "as a unroled user" do
      before do
        sign_in unroled_user
      end

      it "should fail and redirect" do
        post :create, params: {unit: valid_attributes}
        expect(response).to be_redirect
      end

      it "should not create a Unit" do
        expect{
          post :create, params: {unit: valid_attributes}
        }.to_not change{Unit.count}
      end

    end

    describe "as an agent" do
      before do
        sign_in agent
      end

      it "should fail and redirect" do
        post :create, params: {unit: valid_attributes}
        expect(response).to be_redirect
      end

      it "should not create a Unit" do
        expect{
          post :create, params: {unit: valid_attributes}
        }.to_not change{Unit.count}
      end
    end

    describe "as an corporate" do
      before do
        sign_in corporate
      end

      it "should create a Unit with valid attributes" do
        expect{
          post :create, params: {unit: valid_attributes}
        }.to change{Unit.count}.by(1)
        post :create, params: {unit: valid_attributes}
        expect(response).to be_successful
      end
    end

    describe "as an administrator" do
      before do
        sign_in administrator
      end

      it "should create a Unit with valid attributes" do
        expect{
          post :create, params: {unit: valid_attributes}
        }.to change{Unit.count}.by(1)
        post :create, params: {unit: valid_attributes}
        expect(response).to be_successful
      end

      it "should handle invalid attributes" do
        post :create, params: {unit: invalid_attributes}
        expect(response).to be_successful
        expect {
          post :create, params: {unit: invalid_attributes}
        }.to_not change{Unit.count}
      end
    end
  end

  describe "GET #show" do
    let(:unit) { create(:unit) }

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        get :show, params: {id: unit.id}
        expect(response).to be_redirect
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        get :show, params: {id: unit.id}
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should succeed" do
        sign_in agent
        get :show, params: {id: unit.id}
        expect(response).to be_successful
      end
    end

    describe "as an corporate" do
      it "should succeed" do
        sign_in corporate
        get :show, params: {id: unit.id}
        expect(response).to be_successful
      end
    end

    describe "as an administrator" do
      it "should succeed" do
        sign_in administrator
        get :show, params: {id: unit.id}
        expect(response).to be_successful
      end
    end
  end

  describe "GET #edit" do

    let(:unit) { create(:unit) }

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        get :edit, params: {id: unit.id}
        expect(response).to be_redirect
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        get :edit, params: {id: unit.id}
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should fail and redirect" do
        sign_in agent
        get :edit, params: {id: unit.id}
        expect(response).to be_redirect
      end
    end

    describe "as an corporate" do
      it "should succeed" do
        sign_in corporate
        get :edit, params: {id: unit.id}
        expect(response).to be_successful
      end
    end

    describe "as an administrator" do
      it "should succeed" do
        sign_in administrator
        get :edit, params: {id: unit.id}
        expect(response).to be_successful
      end
    end
  end

  describe "PUT #update" do
    let(:unit) { create(:unit) }
    let(:updated_attributes) { {unit: 'foobar12'}}
    let(:invalid_updated_attributes) {
      # Attributes with a duplicate unit
      old_unit = create(:unit)
      {unit: old_unit.unit, property_id: old_unit.property.id}
    }

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        expect{
          put :update, params: {id: unit.id, unit: updated_attributes}
          expect(response).to be_redirect
          unit.reload
        }.to_not change{unit.unit}
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        expect{
          put :update, params: {id: unit.id, unit: updated_attributes}
          expect(response).to be_redirect
          unit.reload
        }.to_not change{unit.unit}
      end
    end

    describe "as an agent" do
      it "should fail and redirect" do
        sign_in agent
        expect{
          put :update, params: {id: unit.id, unit: updated_attributes}
          expect(response).to be_redirect
          unit.reload
        }.to_not change{unit.unit}
      end
    end

    describe "as an corporate" do
      it "should succeed" do
        sign_in corporate
        expect{
          put :update, params: {id: unit.id, unit: updated_attributes}
          expect(response).to be_redirect
          unit.reload
        }.to change{unit.unit}
      end
    end

    describe "as an administrator" do
      before do
        unit
        sign_in administrator
      end

      it "should succeed" do
        expect{
          put :update, params: {id: unit.id, unit: updated_attributes}
          expect(response).to be_redirect
          unit.reload
        }.to change{unit.unit}
      end

      it "should handle invalid attributes" do
        expect{
          put :update, params: {id: unit.id, unit: invalid_updated_attributes}
          expect(response).to be_successful
          unit.reload
        }.to_not change{unit.unit}
      end
    end
  end

  describe "DELETE #destroy" do

    let(:unit) { create(:unit) }

    before do
      unit
    end

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        expect {
          delete :destroy, params: {id: unit.id}
          expect(response).to be_redirect
        }.to_not change{Unit.count}
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        expect {
          delete :destroy, params: {id: unit.id}
          expect(response).to be_redirect
        }.to_not change{Unit.count}
      end
    end

    describe "as an agent" do
      it "should fail and redirect" do
        sign_in agent
        expect {
          delete :destroy, params: {id: unit.id}
          expect(response).to be_redirect
        }.to_not change{Unit.count}
      end
    end

    describe "as an corporate" do
      it "should succeed" do
        sign_in corporate
        expect {
          delete :destroy, params: {id: unit.id}
          expect(response).to be_redirect
        }.to change{Unit.count}.by(-1)
      end
    end

    describe "as an administrator" do
      it "should succeed" do
        sign_in administrator
        expect {
          delete :destroy, params: {id: unit.id}
          expect(response).to be_redirect
        }.to change{Unit.count}.by(-1)
      end
    end
  end

end
