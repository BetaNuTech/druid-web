require 'rails_helper'

RSpec.describe Api::V1::ReferralBouncesController, type: :controller do
  let(:note_action) { create(:lead_action, name: 'External Referral') }
  let(:note_reason) { create(:reason, name: 'Lead Referral') }
  let(:api_token) { 'XXXXXX' }
  let(:property_code) { 'test' }
  let(:campaignid) { 'CID-XXX'}
  let(:trackingid) { 'TRK-XXX'}
  let(:referer) { 'https://example.com' }
  let(:source) {
    create(:lead_source,
      active: true,
      incoming: true,
      slug: 'adbounce',
      api_token: api_token
    )
  }
  let(:property) {
    create(:property)
  }
  let(:property_listing) {
    create(:property_listing,
      property: property,
      code: property_code,
      source: source,
      active: true
    )
  }
  let(:valid_params) {
    {
      propertycode: property_code,
      campaignid:, trackingid: , api_token:
    }
  }

  let(:invalid_params) {
    {
      propertycode: 'bad code',
      campaignid:, trackingid: , api_token:
    }
  }

  describe "GET #refer" do
    before do
      note_action
      note_reason
      property_listing
    end

    describe "with valid params" do
      before do
        request.headers['HTTP_REFERER'] = referer
      end

      it 'should create a ReferralBounce record' do
        expect{
          get :refer, params: valid_params
        }.to change(ReferralBounce, :count).by(1)

        record = ReferralBounce.order(created_at: :desc).limit(1).last
        expect(record.propertycode).to eq(property_code)
        expect(record.campaignid).to eq(campaignid)
        expect(record.trackingid).to eq(trackingid)
        expect(record.referer).to eq(referer)
      end

      it 'should create a note on the property' do
        expect{
          get :refer, params: valid_params
        }.to change(Note, :count).by(1)
        note = Note.order(created_at: :desc).first
        expect(note.notable).to eq(property)
        expect(note.classification).to eq('comment')
      end
    end

    describe "with invalid params" do
      it 'should not create a ReferralBounce record' do
        expect{
          get :refer, params: invalid_params
        }.to_not change(ReferralBounce, :count)
      end
      it 'should create a note on the property' do
        expect{
          get :refer, params: valid_params
        }.to change(Note, :count).by(1)
        note = Note.order(created_at: :desc).first
        expect(note.notable).to eq(property)
        expect(note.classification).to eq('error')
      end

    end
  end
end
