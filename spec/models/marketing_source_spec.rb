# == Schema Information
#
# Table name: marketing_sources
#
#  id                   :uuid             not null, primary key
#  active               :boolean          default(TRUE)
#  property_id          :uuid             not null
#  lead_source_id       :uuid
#  name                 :string           not null
#  description          :text
#  tracking_code        :string
#  tracking_email       :string
#  tracking_number      :string
#  destination_number   :string
#  fee_type             :integer          default("free"), not null
#  fee_rate             :decimal(, )      default(0.0)
#  start_date           :date             not null
#  end_date             :date
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  phone_lead_source_id :uuid
#  email_lead_source_id :uuid
#
require 'rails_helper'

RSpec.describe MarketingSource, type: :model do
  include_context 'users'

  describe 'Initialization' do
    let(:marketing_source) { build(:marketing_source) }

    it 'can be initialized' do
      assert marketing_source
    end

    it 'can be saved' do
      assert marketing_source.save
    end
  end

  describe 'Validation' do
    let(:marketing_source) { build(:marketing_source) }
    let(:property) { create(:property) }

    it 'marketing sources have a unique name within the context of a property' do
      name = 'SourceName'
      assert build(:marketing_source, property: property, name: name).save
      refute build(:marketing_source, property: property, name: name).save
    end
  end

  describe '#property_main_line_missing?' do
    let(:phone_source) { create(:lead_source, slug: 'CallCenter', name: 'CallCenter2') }
    let(:property_with_main_line) { create(:property, phone: '5555551000') }
    let(:property_without_main_line) { create(:property, phone: nil) }

    it 'is true when a tracking number is set and the property has no main line' do
      marketing_source = create(:marketing_source, property: property_without_main_line,
        phone_lead_source: phone_source, tracking_number: '5555550001')

      expect(marketing_source.property_main_line_missing?).to be true
    end

    it 'is false when the property has a main line' do
      marketing_source = create(:marketing_source, property: property_with_main_line,
        phone_lead_source: phone_source, tracking_number: '5555550002')

      expect(marketing_source.property_main_line_missing?).to be false
    end

    it 'is false without a tracking number' do
      marketing_source = create(:marketing_source, property: property_without_main_line,
        lead_source: nil, phone_lead_source: nil, email_lead_source: nil,
        tracking_number: nil, tracking_email: nil, tracking_code: nil,
        destination_number: nil)

      expect(marketing_source.property_main_line_missing?).to be false
    end
  end
end
