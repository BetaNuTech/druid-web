# == Schema Information
#
# Table name: error_alerts
#
#  id               :uuid             not null, primary key
#  fingerprint      :string           not null
#  last_posted_at   :datetime
#  suppressed_count :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
require 'rails_helper'

RSpec.describe ErrorAlert, type: :model do
  let(:now) { Time.current }

  it 'posts the first occurrence with nothing suppressed' do
    expect(ErrorAlert.claim_post('abc', now: now)).to eq(0)
  end

  it 'counts repeats inside the window instead of posting them' do
    ErrorAlert.claim_post('abc', now: now)

    expect(ErrorAlert.claim_post('abc', now: now + 1.minute)).to be_nil
    expect(ErrorAlert.claim_post('abc', now: now + 2.minutes)).to be_nil
    expect(ErrorAlert.find_by(fingerprint: 'abc').suppressed_count).to eq(2)
  end

  it 'posts again after the window with the number held back' do
    ErrorAlert.claim_post('abc', now: now)
    ErrorAlert.claim_post('abc', now: now + 1.minute)

    expect(ErrorAlert.claim_post('abc', now: now + ErrorAlert::WINDOW + 1.minute)).to eq(1)
    expect(ErrorAlert.find_by(fingerprint: 'abc').suppressed_count).to eq(0)
  end

  it 'limits each fingerprint separately' do
    ErrorAlert.claim_post('abc', now: now)

    expect(ErrorAlert.claim_post('def', now: now)).to eq(0)
  end
end
