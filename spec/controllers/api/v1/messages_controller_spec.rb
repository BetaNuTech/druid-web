require 'rails_helper'

RSpec.describe Api::V1::MessagesController, type: :controller do
  render_views

  include_context "cloudmailin_incoming_message"

  describe "POST #create" do
    it "should create a new message" do
      message
      message_count = Message.count
      delivery_count = MessageDelivery.count
      post :create, params: cmi_message_data, format: :json
      expect(assigns[:token]).to eq(cloudmailin_adapter_token)
      expect(assigns[:message].valid?).to be true
      expect(assigns[:message].threadid).to eq(message_threadid)
      expect(Message.count).to eq(message_count + 1)
    end

    it "should return message JSON upon success" do
      message
      post :create, params: cmi_message_data, format: :json
      msg = JSON.parse(response.body)
      expect(msg["user_id"]).to eq(message_user.id)
      expect(msg["threadid"]).to eq(message_threadid)
    end

    it "should return errors with invalid data" do
      invalid_data = cmi_message_data.merge({envelope: nil})
      post :create, params: invalid_data, format: :json
      msg = JSON.parse(response.body)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(msg["errors"]).to be_a(Hash)
    end

    it "should return an error with an invalid token" do
      invalid_data = cmi_message_data.merge({token: 'foobar'})
      post :create, params: invalid_data, format: :json
      msg = JSON.parse(response.body)
      expect(response).to have_http_status(:forbidden)
      expect(msg["errors"]).to be_a(Hash)
    end
  end


end
