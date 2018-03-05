require 'rails_helper'

RSpec.describe ResidentsController, type: :controller do
  include_context "users"
  render_views

  let(:valid_attributes) { build(:resident).attributes }
  let(:invalid_attributes) { {status: "foobar"}}

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
        expect(response).to be_success
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
      it "should succeed" do
        sign_in agent
        get :new
        expect(response).to be_success
      end
    end
  end

  describe "POST #create" do
    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        expect{
          post :create, params: {resident: valid_attributes}
        }.to_not change{Resident.count}
        post :create, params: {resident: valid_attributes}
        expect(response).to be_redirect
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        expect{
          post :create, params: {resident: valid_attributes}
        }.to_not change{Resident.count}
        post :create, params: {resident: valid_attributes}
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should create a new resident" do
        sign_in agent
        expect{
          post :create, params: {resident: valid_attributes}
        }.to change{Resident.count}.by(1)
        post :create, params: {resident: valid_attributes}
        expect(response).to be_redirect
      end
    end

    describe "with invalid attributes" do
      let(:invalid_new_attributes) { build(:resident, {status: "Invalid", first_name: "Foobar"}).attributes }
      it "should handle the validation error" do
        sign_in agent
        expect{
          post :create, params: {resident: invalid_new_attributes}
        }.to_not change{Resident.count}
      end
    end
  end

  describe "GET #show" do
    let(:resident) { create(:resident) }
    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        get :show, params: {id: resident.id}
        expect(response).to be_redirect
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        get :show, params: {id: resident.id}
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should succeed" do
        sign_in agent
        get :show, params: {id: resident.id}
        expect(response).to be_success
      end
    end
  end

  describe "GET #edit" do
    let(:resident) { create(:resident) }
    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        get :edit, params: {id: resident.id}
        expect(response).to be_redirect
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        get :edit, params: {id: resident.id}
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should succeed" do
        sign_in agent
        get :edit, params: {id: resident.id}
        expect(response).to be_success
      end
    end
  end

  describe "PUT #update" do
    let(:resident) { create(:resident) }
    let(:valid_new_attributes) { {first_name: "Foobar" } }

    before(:each) do
      resident
    end

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        expect{
          put :update, params: {id: resident.id, resident: valid_new_attributes}
        }.to_not change{ resident.first_name }
        put :update, params: {id: resident.id, resident: valid_new_attributes}
        expect(response).to be_redirect
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        expect{
          put :update, params: {id: resident.id, resident: valid_new_attributes}
        }.to_not change{ resident.first_name }
        put :update, params: {id: resident.id, resident: valid_new_attributes}
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should succeed" do
        sign_in agent
        expect{
          put :update, params: {id: resident.id, resident: valid_new_attributes}
          resident.reload
        }.to change{ resident.first_name }
        put :update, params: {id: resident.id, resident: valid_new_attributes}
        expect(response).to be_redirect
      end

      describe "with invalid attributes" do
        let(:invalid_new_attributes) { {status: "Invalid", first_name: "Foobar"}}
        it "should handle the validation error" do
          sign_in agent
          expect{
            put :update, params: {id: resident.id, resident: invalid_new_attributes}
            resident.reload
          }.to_not change{ resident.first_name }
        end
      end
    end

    describe "as an operator" do
      it "should succeed" do
        sign_in operator
        expect{
          put :update, params: {id: resident.id, resident: valid_new_attributes}
          resident.reload
        }.to change{ resident.first_name }
        put :update, params: {id: resident.id, resident: valid_new_attributes}
        expect(response).to be_redirect
      end
    end
  end

  describe "DELETE #destroy" do
    let(:resident) { create(:resident) }
    before(:each) do
      resident
    end

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        expect{
          delete :destroy, params: {id: resident.id}
        }.to_not change{Resident.count}
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        expect{
          sign_in unroled_user
          delete :destroy, params: {id: resident.id}
        }.to_not change{Resident.count}
      end
    end

    describe "as an agent" do
      it "should succeed and delete the record" do
        sign_in agent
        delete :destroy, params: {id: resident.id}
        expect(Resident.where(id: resident.id).count).to eq(0)
      end

    end

    describe "as an operator" do
      it "should succeed and delete the record" do
        sign_in operator
        delete :destroy, params: {id: resident.id}
        expect(Resident.where(id: resident.id).count).to eq(0)
      end
    end

  end
end
