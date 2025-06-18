require 'rails_helper'

RSpec.describe Leads::ResidentValidator do
  let(:property) { create(:property) }
  let(:resident) { create(:resident, property: property, status: 'current') }
  let(:resident_detail) { create(:resident_detail, resident: resident) }

  let(:lead_data) do
    {
      first_name: 'John',
      last_name: 'Doe',
      phone1: '5551234567',
      phone2: '5559876543',
      email: 'john.doe@example.com'
    }
  end

  subject { described_class.new(property: property, lead_data: lead_data) }

  describe '#resident_match?' do
    context 'when no property is provided' do
      let(:property) { nil }

      it 'returns false' do
        expect(subject.resident_match?).to be false
      end
    end

    context 'when matching by phone1' do
      before do
        resident_detail.update!(phone1: '5551234567')
      end

      it 'returns true and sets matching_resident' do
        expect(subject.resident_match?).to be true
        expect(subject.matching_resident).to be_present
        expect(subject.matching_resident['resident_id']).to eq(resident.id)
      end
    end

    context 'when matching by phone2' do
      before do
        resident_detail.update!(phone2: '5559876543')
      end

      it 'returns true' do
        expect(subject.resident_match?).to be true
      end
    end

    context 'when matching by email' do
      before do
        resident_detail.update!(email: 'john.doe@example.com')
      end

      it 'returns true' do
        expect(subject.resident_match?).to be true
      end
    end

    context 'when matching by first and last name' do
      before do
        resident.update!(first_name: 'John', last_name: 'Doe')
        resident_detail # ensure resident_detail exists
      end

      it 'returns true' do
        expect(subject.resident_match?).to be true
      end
    end

    context 'when only first name matches' do
      before do
        resident.update!(first_name: 'John', last_name: 'Smith')
      end

      it 'returns false' do
        expect(subject.resident_match?).to be false
      end
    end

    context 'when resident is not current' do
      before do
        resident.update!(status: 'former')
        resident_detail.update!(phone1: '5551234567')
      end

      it 'returns false' do
        expect(subject.resident_match?).to be false
      end
    end

    context 'when resident is from different property' do
      let(:other_property) { create(:property) }
      let(:other_resident) { create(:resident, property: other_property, status: 'current') }
      let(:other_resident_detail) { create(:resident_detail, resident: other_resident, phone1: '5551234567') }

      before do
        other_resident_detail
      end

      it 'returns false' do
        expect(subject.resident_match?).to be false
      end
    end

    context 'with invalid phone values' do
      let(:lead_data) do
        {
          phone1: '5555555555', # Invalid test number
          phone2: '1234567890'  # Invalid test number
        }
      end

      before do
        resident_detail.update!(phone1: '5555555555')
      end

      it 'returns false' do
        expect(subject.resident_match?).to be false
      end
    end

    context 'with invalid email values' do
      let(:lead_data) do
        {
          email: 'noemail@gmail.com' # Invalid test email
        }
      end

      before do
        resident_detail.update!(email: 'noemail@gmail.com')
      end

      it 'returns false' do
        expect(subject.resident_match?).to be false
      end
    end

    context 'with invalid name values' do
      let(:lead_data) do
        {
          first_name: 'UNKNOWN',
          last_name: 'UNAVAILABLE'
        }
      end

      before do
        resident.update!(first_name: 'UNKNOWN', last_name: 'UNAVAILABLE')
      end

      it 'returns false' do
        expect(subject.resident_match?).to be false
      end
    end

    context 'when no email is provided in lead data' do
      let(:lead_data) do
        {
          first_name: 'John',
          last_name: 'Doe',
          phone1: '5551234567',
          phone2: nil,
          email: nil
        }
      end

      before do
        resident_detail.update!(phone1: '5551234567', email: 'resident@example.com')
      end

      it 'still matches by phone and does not check email' do
        expect(subject.resident_match?).to be true
      end
    end

    context 'when multiple conditions match' do
      before do
        resident.update!(first_name: 'John', last_name: 'Doe')
        resident_detail.update!(phone1: '5551234567', email: 'john.doe@example.com')
      end

      it 'returns true' do
        expect(subject.resident_match?).to be true
      end
    end
  end
end
