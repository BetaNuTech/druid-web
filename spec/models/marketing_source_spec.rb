# == Schema Information
#
# Table name: marketing_sources
#
#  id                 :uuid             not null, primary key
#  active             :boolean          default(TRUE)
#  property_id        :uuid             not null
#  lead_source_id     :uuid
#  name               :string           not null
#  description        :text
#  tracking_code      :string
#  tracking_email     :string
#  tracking_number    :string
#  destination_number :string
#  fee_type           :integer          default("free"), not null
#  fee_rate           :decimal(, )      default(0.0)
#  start_date         :date             not null
#  end_date           :date
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
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
end
