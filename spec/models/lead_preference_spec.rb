# == Schema Information
#
# Table name: lead_preferences
#
#  id                :uuid             not null, primary key
#  lead_id           :uuid
#  min_area          :integer
#  max_area          :integer
#  min_price         :decimal(, )
#  max_price         :decimal(, )
#  move_in           :datetime
#  baths             :decimal(, )
#  pets              :boolean
#  smoker            :boolean
#  washerdryer       :boolean
#  notes             :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  beds              :integer
#  raw_data          :text
#  unit_type_id      :uuid
#  optout_email      :boolean          default(FALSE)
#  optout_email_date :datetime
#  optin_sms         :boolean          default(FALSE)
#  optin_sms_date    :datetime
#

require 'rails_helper'

RSpec.describe LeadPreference, type: :model do
  include_context "messaging"

  let(:lead_preference) { create(:lead_preference) }
  let(:valid_attributes) {
    {
      min_area: 1,
      max_area: 2,
      min_price: 1,
      max_price: 2
    }
  }

  describe :associations do
    it "must be associated with a Lead" do
      pref = LeadPreference.new(valid_attributes)
      pref.save
      refute(pref.valid?)
      pref.lead = create(:lead)
      pref.save
      assert(pref.valid?)
    end

    it "may have a unit_type" do
      assert(lead_preference.unit_type.present?)
      lead_preference.unit_type = nil
      lead_preference.save
      assert(lead_preference.valid?)
    end

    it "returns the preference's unit_type name" do
      expect(lead_preference.unit_type_name).to eq(lead_preference.unit_type.name)
      lead_preference.unit_type = nil
      lead_preference.save
      expect(lead_preference.unit_type_name).to eq(LeadPreference::NO_UNIT_PREFERENCE)
    end

  end

  it "must have a min_area smaller than max_area" do
    min, max = [100, 200]
    lead = create(:lead)
    pref = lead.preference

    validate_min_max = Proc.new { |pref, min,max,is_valid|
      pref.min_area = min
      pref.max_area = max
      pref.validate
      expect(pref.valid?).to eq(is_valid)
    }

    # Valid where min < max
    validate_min_max.call(pref, 100, 200, true)

    # Valid where max is nil
    validate_min_max.call(pref, 100, nil, true)

    # Invalid where min > max
    validate_min_max.call(pref, 200, 100, false)
  end

  it "must have a min_price smaller than max_price" do
    min, max = [100, 200]
    lead = create(:lead)
    pref = lead.preference

    validate_min_max = Proc.new { |pref, min,max,is_valid|
      pref.min_price = min
      pref.max_price = max
      pref.validate
      expect(pref.valid?).to eq(is_valid)
    }

    # Valid where min < max
    validate_min_max.call(pref, 100, 200, true)

    # Valid where max is nil
    validate_min_max.call(pref, 100, nil, true)

    # Invalid where min > max
    validate_min_max.call(pref, 200, 100, false)
  end

  it "has a unit system" do
    pref = LeadPreference.new
    expect(pref.unit_system).to eq(:imperial)
  end

  describe 'messaging preferences' do
    let(:lead) { create(:lead, state: 'prospect') }
    describe 'sms authorization' do
      it 'should set sms optin flag and timestamp' do
        lead.preference.optin_sms = false
        lead.preference.optin_sms_date = nil
        lead.preference.save!
        lead.preference.optin_sms!
        expect(lead.preference.optin_sms).to eq(true)
        expect(lead.preference.optin_sms_date).to_not eq(nil)
      end
      it 'should set sms optout flag and timestamp' do
        timestamp = DateTime.current
        lead.preference.optin_sms = true
        lead.preference.optin_sms_date = timestamp
        lead.preference.save!
        lead.preference.optout_sms!
        expect(lead.preference.optin_sms).to eq(false)
        expect(lead.preference.optin_sms_date).to_not eq(timestamp)
        lead.preference.optin_sms!
        expect(lead.preference.optin_sms).to eq(true)
        expect(lead.preference.optin_sms_date).to_not eq(nil)
      end
      it 'should return sms authorization status' do
        lead.preference.optin_sms!
        assert(lead.preference.optin_sms?)
        lead.preference.optout_sms!
        refute(lead.preference.optin_sms?)
      end
      describe 'incoming message handling' do
        let(:message_delivery) {
          message = create(:message, subject: 'none', body: 'test', message_type: sms_message_type, state: 'sent')
          MessageDelivery.create(message: message, message_type: message.message_type) 
        }
        let(:message) { message_delivery.message }

        describe 'when sms is not already authorized' do
          describe 'when the message exactly matches an affirmative keyword' do
            it 'should optin sms' do
              ['yes', 'start', 'si'].each do |keyword|
                lead.preference.optin_sms = false; lead.preference.save
                refute(lead.preference.optin_sms?)
                message.body = keyword; message.save; message_delivery.reload
                lead.preference.handle_sms_reply(message_delivery)
                assert(lead.preference.optin_sms?)
              end

              keyword = 'foobar'
              lead.preference.optin_sms = false; lead.preference.save
              refute(lead.preference.optin_sms?)
              message.body = keyword; message.save; message_delivery.reload
              lead.preference.handle_sms_reply(message_delivery)
              refute(lead.preference.optin_sms?)
            end
          end
          describe 'when the message exactly matches a dissenting keyword' do
            it 'should do nothing' do
            end
          end
        end
        describe 'when sms is currently authorized' do

        end
      end
    end
    describe 'email authorization' do
      it 'should set email optin flag and timestamp' do
        lead.preference.optout_email = true
        lead.preference.optout_email_date = nil
        lead.preference.save!
        lead.preference.optout_email!
        expect(lead.preference.optout_email).to eq(true)
        expect(lead.preference.optout_email_date).to_not eq(nil)
        lead.preference.optin_email!
        expect(lead.preference.optout_email).to eq(false)
        expect(lead.preference.optout_email_date).to eq(nil)
      end
      it 'should set email optout flag and timestamp' do
        timestamp = DateTime.current
        lead.preference.optout_email = false
        lead.preference.optout_email_date = nil
        lead.preference.save!
        lead.preference.optout_email!
        expect(lead.preference.optout_email).to eq(true)
        expect(lead.preference.optout_email_date).to_not eq(nil)
        lead.preference.optin_email!
        expect(lead.preference.optout_email).to eq(false)
        expect(lead.preference.optout_email_date).to eq(nil)
      end
      it 'should return email authorization status' do
        lead.preference.optout_email!
        assert(lead.preference.optout_email?)
        lead.preference.optin_email!
        refute(lead.preference.optout_email?)
      end
    end
  
  end

end
