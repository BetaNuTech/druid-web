require 'rails_helper'

RSpec.describe MarketingExpensesController, type: :controller do
  include_context 'users'
  render_views

  let(:lead_source) { create(:bluesky_source) }
  let(:property) { agent.property }
  let(:marketing_source) { create(:marketing_source, property_id: property.id, lead_source: lead_source) }
  let(:valid_attributes) { attributes_for(:marketing_expense, property: property, marketing_source: marketing_source) }
  let(:invalid_attributes) { attributes_for(:marketing_expense, fee_amount: nil, start_date: nil, property: property, marketing_source: marketing_source) }
  let(:marketing_expense) { create(:marketing_expense, valid_attributes) }

  before(:each) do
    marketing_source
  end

  describe "GET #index" do
    describe "as a corporate user" do
      it "should fail" do
        sign_in corporate
        expect {
          get :index, params: {marketing_source_id: marketing_source.id}
        }.to(raise_error)
      end
    end
  end

  describe "GET #new" do
    describe "as a corporate user" do
      it "should succeed" do
        sign_in corporate
        get :new, params: {marketing_source_id: marketing_source.id}
        expect(response).to render_template(:new)
      end
    end
    describe "as a manager" do
      it "should fail" do
        sign_in manager
        get :new, params: {marketing_source_id: marketing_source.id}
        expect(response).to redirect_to(root_path)
      end
    end
  end
  describe "POST #create" do
    describe "as a corporate user" do
      describe "with valid attributes" do
        it "should succeed" do
          sign_in corporate
          count = MarketingExpense.count
          post :create, params: {marketing_source_id: marketing_source.id, marketing_expense: valid_attributes}
          expect(MarketingExpense.count).to eq(count + 1)
          expect(response).to redirect_to(marketing_sources_path(property_id: property.id) + "##{marketing_source.id}")
        end
      end
      describe "with invalid attributes" do
        it "should fail" do
          sign_in corporate
          count = MarketingExpense.count
          post :create, params: {marketing_source_id: marketing_source.id, marketing_expense: invalid_attributes}
          expect(MarketingExpense.count).to eq(count)
          expect(response).to render_template(:new)
        end
      end
    end
    describe "as a manager" do
      it "should fail" do
        sign_in manager
        count = MarketingExpense.count
        post :create, params: {marketing_source_id: marketing_source.id, marketing_expense: invalid_attributes}
        expect(MarketingExpense.count).to eq(count)
        expect(response).to redirect_to(root_path)
      end
    end
  end
  describe "GET #edit" do
    before(:each) do
      marketing_expense
    end
    describe "as a corporate user" do
      it "should succeed" do
        sign_in corporate
        get :edit, params: {marketing_source_id: marketing_source.id, id: marketing_expense.id}
        expect(response).to be_successful
        expect(response).to render_template(:edit)
      end
    end
    describe "as a manager" do
      it "should fail" do
        sign_in manager
        get :edit, params: {marketing_source_id: marketing_source.id, id: marketing_expense.id}
        expect(response).to redirect_to(root_path)
      end
    end
  end
  describe "PUT #update" do
    let(:valid_update_attributes) { valid_attributes.merge({fee_total: 200.0}) }
    let(:invalid_update_attributes) { valid_attributes.merge({fee_total: -1}) }
    before(:each) do
      marketing_expense
    end
    describe "as a corporate user" do
      describe "with valid attributes" do
        it "should succeed" do
          sign_in corporate
          expect(marketing_expense.fee_total).to_not eq(valid_update_attributes[:fee_total])
          put :update, params: { marketing_source_id: marketing_source.id, id: marketing_expense.id, marketing_expense: valid_update_attributes}
          marketing_expense.reload
          expect(marketing_expense.fee_total).to eq(valid_update_attributes[:fee_total])
        end
      end
      describe "with invalid attributes" do
        it "should fail" do
          sign_in corporate
          original_fee_total = marketing_expense.fee_total
          put :update, params: { marketing_source_id: marketing_source.id, id: marketing_expense.id, marketing_expense: invalid_update_attributes}
          marketing_expense.reload
          expect(marketing_expense.fee_total).to eq(original_fee_total)
          expect(response).to render_template(:edit)
        end
      end
    end
  end
  describe "DELETE #destroy" do
    describe "as a corporate user" do
      it "should succeed" do
        sign_in corporate
        id = marketing_expense.id
        delete :destroy, params: {marketing_source_id: marketing_source.id, id: marketing_expense.id}
        expect(response).to redirect_to(marketing_sources_path(property_id: property.id))
        expect(MarketingExpense.where(id: id).count).to eq(0)
      end
    end
    describe "as a manager" do
      it "should fail" do
        sign_in manager
        id = marketing_expense.id
        delete :destroy, params: {marketing_source_id: marketing_source.id, id: marketing_expense.id}
        expect(response).to redirect_to(root_path)
        expect(MarketingExpense.where(id: id).count).to eq(1)
      end
    end
  end

end
