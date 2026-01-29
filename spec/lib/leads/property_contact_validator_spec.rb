require 'rails_helper'

RSpec.describe Leads::PropertyContactValidator do
  let(:property) do
    create(:property,
      email: 'leasing@vintage-edge.com',
      website: 'www.vintage-edge.com',
      phone: '5551234567',
      leasing_phone: '5552345678',
      maintenance_phone: '5553456789'
    )
  end

  let(:lead_data) do
    {
      first_name: 'John',
      last_name: 'Doe',
      phone1: '5559999999',
      phone2: nil,
      email: 'john.doe@gmail.com'
    }
  end

  subject { described_class.new(property: property, lead_data: lead_data) }

  describe '#validate' do
    context 'when no property is provided' do
      let(:property) { nil }

      it 'returns :ok' do
        expect(subject.validate).to eq(:ok)
        expect(subject.should_reject?).to be false
        expect(subject.should_modify?).to be false
      end
    end

    context 'when neither email nor phone match property' do
      it 'returns :ok' do
        expect(subject.validate).to eq(:ok)
        expect(subject.should_reject?).to be false
        expect(subject.should_modify?).to be false
      end
    end

    context 'rejection scenarios' do
      context 'when both email domain and phone match property' do
        let(:lead_data) do
          {
            phone1: '5551234567',
            phone2: nil,
            email: 'anyone@vintage-edge.com'
          }
        end

        it 'rejects the lead' do
          expect(subject.validate).to eq(:reject)
          expect(subject.should_reject?).to be true
          expect(subject.rejection_reason).to eq("Lead email domain and phone match property contact info")
        end
      end

      context 'when email domain matches and no phone provided' do
        let(:lead_data) do
          {
            phone1: nil,
            phone2: nil,
            email: 'anyone@vintage-edge.com'
          }
        end

        it 'rejects the lead' do
          expect(subject.validate).to eq(:reject)
          expect(subject.should_reject?).to be true
          expect(subject.rejection_reason).to eq("Lead email domain matches property (no alternative contact)")
        end
      end

      context 'when phone matches and no email provided' do
        let(:lead_data) do
          {
            phone1: '5551234567',
            phone2: nil,
            email: nil
          }
        end

        it 'rejects the lead' do
          expect(subject.validate).to eq(:reject)
          expect(subject.should_reject?).to be true
          expect(subject.rejection_reason).to eq("Lead phone matches property (no alternative contact)")
        end
      end
    end

    context 'modification scenarios' do
      context 'when email domain matches but phone does not' do
        let(:lead_data) do
          {
            phone1: '5559999999',
            phone2: nil,
            email: 'anyone@vintage-edge.com'
          }
        end

        it 'modifies to nil the email' do
          expect(subject.validate).to eq(:modify)
          expect(subject.should_modify?).to be true
          expect(subject.modifications[:email]).to be_nil
          expect(subject.modifications[:reason]).to eq("Email domain matched property")
        end
      end

      context 'when phone matches but email does not' do
        let(:lead_data) do
          {
            phone1: '5551234567',
            phone2: nil,
            email: 'realuser@gmail.com'
          }
        end

        it 'modifies to nil the phones' do
          expect(subject.validate).to eq(:modify)
          expect(subject.should_modify?).to be true
          expect(subject.modifications[:phone1]).to be_nil
          expect(subject.modifications[:phone2]).to be_nil
          expect(subject.modifications[:reason]).to eq("Phone matched property")
        end
      end
    end

    context 'domain matching' do
      context 'when lead email domain matches property email domain' do
        let(:lead_data) { { email: 'test@vintage-edge.com', phone1: nil, phone2: nil } }

        it 'detects the match' do
          subject.validate
          expect(subject.should_reject?).to be true
        end
      end

      context 'when lead email domain matches property website domain' do
        let(:property) do
          create(:property,
            email: 'info@other-domain.com',
            website: 'www.vintage-edge.com',
            phone: '5551234567'
          )
        end
        let(:lead_data) { { email: 'test@vintage-edge.com', phone1: nil, phone2: nil } }

        it 'detects the match via website' do
          subject.validate
          expect(subject.should_reject?).to be true
        end
      end

      context 'when website has no www prefix' do
        let(:property) do
          create(:property,
            email: nil,
            website: 'vintage-edge.com',
            phone: '5551234567'
          )
        end
        let(:lead_data) { { email: 'test@vintage-edge.com', phone1: nil, phone2: nil } }

        it 'detects the match' do
          subject.validate
          expect(subject.should_reject?).to be true
        end
      end

      context 'when website has https protocol' do
        let(:property) do
          create(:property,
            email: nil,
            website: 'https://www.vintage-edge.com',
            phone: '5551234567'
          )
        end
        let(:lead_data) { { email: 'test@vintage-edge.com', phone1: nil, phone2: nil } }

        it 'detects the match' do
          subject.validate
          expect(subject.should_reject?).to be true
        end
      end

      context 'when email domain is different' do
        let(:lead_data) { { email: 'test@gmail.com', phone1: '5559999999', phone2: nil } }

        it 'does not detect a match' do
          expect(subject.validate).to eq(:ok)
        end
      end
    end

    context 'phone matching' do
      context 'when lead phone1 matches property main phone' do
        let(:lead_data) { { email: nil, phone1: '5551234567', phone2: nil } }

        it 'detects the match' do
          subject.validate
          expect(subject.should_reject?).to be true
        end
      end

      context 'when lead phone2 matches property phone' do
        let(:lead_data) { { email: nil, phone1: '5559999999', phone2: '5551234567' } }

        it 'detects the match' do
          subject.validate
          expect(subject.should_reject?).to be true
        end
      end

      context 'when lead phone matches property leasing_phone' do
        let(:lead_data) { { email: nil, phone1: '5552345678', phone2: nil } }

        it 'detects the match' do
          subject.validate
          expect(subject.should_reject?).to be true
        end
      end

      context 'when lead phone matches property maintenance_phone' do
        let(:lead_data) { { email: nil, phone1: '5553456789', phone2: nil } }

        it 'detects the match' do
          subject.validate
          expect(subject.should_reject?).to be true
        end
      end

      context 'when phone has formatting differences' do
        let(:lead_data) { { email: nil, phone1: '(555) 123-4567', phone2: nil } }

        it 'normalizes and detects the match' do
          subject.validate
          expect(subject.should_reject?).to be true
        end
      end

      context 'when phone has country code prefix' do
        let(:lead_data) { { email: nil, phone1: '15551234567', phone2: nil } }

        it 'normalizes and detects the match' do
          subject.validate
          expect(subject.should_reject?).to be true
        end
      end

      context 'when phone is different' do
        let(:lead_data) { { email: 'test@gmail.com', phone1: '5559999999', phone2: nil } }

        it 'does not detect a match' do
          expect(subject.validate).to eq(:ok)
        end
      end
    end

    context 'phone_numbers association matching' do
      let!(:additional_phone) do
        create(:phone_number, phoneable: property, number: '5554567890', name: 'Secondary Line')
      end

      context 'when lead phone matches a property phone_number record' do
        let(:lead_data) { { email: nil, phone1: '5554567890', phone2: nil } }

        it 'detects the match' do
          subject.validate
          expect(subject.should_reject?).to be true
        end
      end
    end

    context 'edge cases' do
      context 'when lead email is blank string' do
        let(:lead_data) { { email: '', phone1: '5559999999', phone2: nil } }

        it 'handles gracefully' do
          expect(subject.validate).to eq(:ok)
        end
      end

      context 'when lead phone is blank string' do
        let(:lead_data) { { email: 'test@gmail.com', phone1: '', phone2: '' } }

        it 'handles gracefully' do
          expect(subject.validate).to eq(:ok)
        end
      end

      context 'when property has no email or website' do
        let(:property) do
          create(:property, email: nil, website: nil, phone: '5551234567')
        end
        let(:lead_data) { { email: 'test@vintage-edge.com', phone1: '5559999999', phone2: nil } }

        it 'only checks phone matching' do
          expect(subject.validate).to eq(:ok)
        end
      end

      context 'when property has no phones' do
        let(:property) do
          create(:property,
            email: 'leasing@vintage-edge.com',
            website: 'www.vintage-edge.com',
            phone: nil,
            leasing_phone: nil,
            maintenance_phone: nil
          )
        end
        let(:lead_data) { { email: 'test@gmail.com', phone1: '5551234567', phone2: nil } }

        it 'only checks email matching' do
          expect(subject.validate).to eq(:ok)
        end
      end

      context 'when lead email has uppercase' do
        let(:lead_data) { { email: 'Test@Vintage-Edge.COM', phone1: nil, phone2: nil } }

        it 'normalizes and detects the match' do
          subject.validate
          expect(subject.should_reject?).to be true
        end
      end

      context 'when property website has invalid URI' do
        let(:property) do
          create(:property,
            email: 'leasing@vintage-edge.com',
            website: 'not a valid url [invalid]',
            phone: '5551234567'
          )
        end
        let(:lead_data) { { email: 'test@gmail.com', phone1: '5559999999', phone2: nil } }

        it 'handles gracefully and continues validation' do
          expect(subject.validate).to eq(:ok)
        end
      end
    end
  end

  describe '#should_reject?' do
    it 'returns false before validation' do
      expect(subject.should_reject?).to be false
    end

    context 'after validation with rejection' do
      let(:lead_data) { { email: 'test@vintage-edge.com', phone1: nil, phone2: nil } }

      it 'returns true' do
        subject.validate
        expect(subject.should_reject?).to be true
      end
    end
  end

  describe '#should_modify?' do
    it 'returns false before validation' do
      expect(subject.should_modify?).to be false
    end

    context 'after validation with modification' do
      let(:lead_data) { { email: 'test@vintage-edge.com', phone1: '5559999999', phone2: nil } }

      it 'returns true' do
        subject.validate
        expect(subject.should_modify?).to be true
      end
    end
  end
end
