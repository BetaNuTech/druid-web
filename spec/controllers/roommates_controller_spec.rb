require 'rails_helper'

RSpec.describe RoommatesController, type: :controller do
  include_context "users"
  include_context "messaging"
  render_views

  let(:lead) { create(:lead, property: agent.property, user: agent)}
  let(:roommate) { create(:roommate, lead: lead) }
  let(:valid_attributes) { attributes_for(:roommate) }
  let(:invalid_attributes) { valid_attributes.merge({phone: nil, email: nil}) }

  #describe "GET #index" do
    #describe "as an agent" do
      #it "should fail and redirect" do
        #sign_in agent
        #get :index, params: {lead_id: lead.id}
        #expect(response).to have_http_status(302)
      #end
    #end
  #end

  describe "GET #new" do
    describe "as an agent" do
      it "should success" do
        sign_in agent
        get :new, params: {lead_id: lead.id}
        expect(response).to have_http_status(200)
        expect(response).to render_template('new')
      end
    end
  end

  describe "POST #create" do
    describe "with valid data" do
      it "should create a new roommate record" do
        sign_in agent
        expect(lead.roommates.count).to eq(0)
        post( :create, params: {lead_id: lead.id, roommate: valid_attributes} )
        expect(response).to have_http_status(302)
        expect(assigns[:roommate]).to be_valid
        expect(lead.roommates.count).to eq(1)
      end
    end

    describe "with invalid_data" do
      it "should re-render the form" do
        sign_in agent
        expect(lead.roommates.count).to eq(0)
        post(:create, params: {lead_id: lead.id, roommate: invalid_attributes})
        expect(response).to have_http_status(200)
        expect(response).to render_template('new')
        expect(assigns[:roommate]).to be_invalid
        expect(lead.roommates.count).to eq(0)
      end
    end
  end

  describe "GET #edit" do
    describe "as an agent" do
      it "should be successful" do
        sign_in agent
        get(:edit, params: {lead_id: lead.id, id: roommate.id})
        expect(response).to render_template('edit')
        expect(response).to have_http_status(200)
        expect(assigns[:roommate]).to eq(roommate)
      end
    end
  end

  describe "PUT #update" do
    let(:new_name) { 'Foobarquux' }
    let(:valid_new_attributes) { valid_attributes.merge(first_name: new_name)}
    let(:invalid_new_attributes) { valid_new_attributes.merge(email: nil, phone: nil)}
    describe "with valid params" do
      describe "as an agent" do
        it "should update the roommate record" do
          sign_in agent
          put :update, params: {lead_id: lead.id, id: roommate.id, roommate: valid_new_attributes}
          expect(response).to redirect_to(lead_path(lead))
          roommate.reload
          expect(roommate.first_name).to eq(new_name)
        end
      end
    end

    describe "with invalid params" do
      describe "as an agent" do
        it "should re-render the form" do
          sign_in agent
          put :update, params: {lead_id: lead.id, id: roommate.id, roommate: invalid_new_attributes}
          expect(response).to render_template('edit')
          expect(assigns[:roommate]).to be_invalid
          expect(assigns[:roommate].first_name).to eq(new_name)
        end
      end
    end
  end

  describe "DELETE #destroy" do
    describe "as an agent" do
      it "should delete the roommate record" do
        roommate
        roommate_count = Roommate.count
        sign_in agent
        delete :destroy, params:{lead_id: lead.id, id: roommate.id}
        expect(response).to redirect_to(lead_path(lead))
        expect(Roommate.count).to eq(roommate_count - 1)
      end
    end
  end

end
