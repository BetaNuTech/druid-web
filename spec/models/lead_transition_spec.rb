# == Schema Information
#
# Table name: lead_transitions
#
#  id             :uuid             not null, primary key
#  lead_id        :uuid             not null
#  last_state     :string           not null
#  current_state  :string           not null
#  classification :integer
#  memo           :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'rails_helper'

RSpec.describe LeadTransition, type: :model do

  let(:lead_transition) { build(:lead_transition) }

  it "can be initialized" do
    assert lead_transition.valid?
  end

  it "can be saved" do
    assert lead_transition.save
  end

  describe "associations" do
    it "has a lead" do
      expect(lead_transition.lead).to be_a(Lead)
    end
  end

  describe "classifications" do
    let(:valid_classifications) { %w{lead vendor resident duplicate other}  }
    it "has a classification" do
      expect(LeadTransition.classifications.keys.size).to eq(5)
      valid_classifications.each do |c13n|
        lead_transition.classification = c13n
      end
      expect{ lead_transition.classification = 'foobar'}.to raise_error(ArgumentError)
    end
  end

end
