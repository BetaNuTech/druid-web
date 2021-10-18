require 'rails_helper'

RSpec.describe IncomingLeadsChannel, type: :channel do
  include_context 'users'
  include_context "messaging"

  let(:user) { agent; agent.switch_setting!(:lead_web_notifications, true); agent }
  let(:lead1){ create(:lead, property: property, state: 'open') }
  let(:property) { user.property }
  let(:property_stream) { lead1.property_incoming_leads_stream_name }
  let(:property2) { create(:property) }

  describe "subscription by authenticated user" do

    before do
      stub_connection current_user: user
    end

    it "successfully subscribes to own property" do
      subscribe(property_id: property.id)
      expect(subscription).to be_confirmed
      expect(subscription.current_user).to eq user
    end

    it "rejects subscription to unauthorized property" do
      subscribe(property_id: property2.id)
      expect(subscription).to be_rejected
    end

    it "streams broadcasts" do
      subscribe(property_id: property.id)
      expect {
        ActionCable.server.broadcast(property_stream, lead: lead1.to_json)
      }.to have_broadcasted_to(property_stream)
    end

  end

  describe "subscription by unauthenticated user" do
    before do
      stub_connection current_user: nil
    end

    it "rejects subscription" do
      subscribe(property_id: agent.property.id)
      expect(subscription).to be_rejected
    end
  end

  describe "broadcasts resulting from new Leads" do
    include_context "lead_creator"

    let(:valid_attrs) {
      lead_creator_property_listing
      {
        data: FactoryBot.attributes_for(:lead, property_id: lead_creator_property.id),
        token: default_lead_source.api_token,
        agent: nil
      }
    }

    before do
      stub_connection current_user: user
    end

    it "should make a broadcast when Leads::Creator creates a Lead" do
      subscribe(property_id: property.id)
      creator = Leads::Creator.new(**valid_attrs)
      expect{
        creator.call
      }.to have_broadcasted_to(property_stream)
    end

  end
end
