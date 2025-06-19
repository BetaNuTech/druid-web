require 'rails_helper'

RSpec.describe Leads::Creator do
  let(:property) { create(:property) }
  let(:lead_source) { create(:lead_source, slug: 'Bluesky') }
  let(:property_listing) { create(:property_listing, property: property, source: lead_source, code: property.id) }

  let(:valid_lead_data) do
    {
      first_name: 'John',
      last_name: 'Doe',
      email: 'john@example.com',
      phone1: '5551234567',
      property_id: property.id
    }
  end

  before do
    property_listing
  end

  describe '#call' do
    context 'with normal lead creation' do
      before do
        # Mock all ENV calls properly
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with('ENABLE_OPENAI_PARSER', 'false').and_return('false')
      end

      it 'creates a lead successfully' do
        creator = described_class.new(data: valid_lead_data, token: lead_source.api_token)
        result_lead = creator.call

        expect(result_lead.errors).to be_empty
        expect(creator.status).to eq(:ok)
      end
    end

    context 'with async processing status' do
      let(:mock_parser) { double('Parser') }
      let(:async_result) do
        Leads::Creator::Result.new(
          status: :async_processing,
          lead: {},
          errors: ActiveModel::Errors.new(Lead.new),
          property_code: property.id.to_s,
          parser: 'OpenAI (Async)'
        )
      end

      before do
        allow(described_class).to receive(:get_parser).and_return(Leads::Adapters::Bluesky)
        allow_any_instance_of(Leads::Adapters::Bluesky).to receive(:parse).and_return(async_result)
      end

      it 'does not create a lead and returns empty lead with error' do
        creator = described_class.new(data: valid_lead_data, token: lead_source.api_token)

        expect do
          result_lead = creator.call
          expect(result_lead).not_to be_persisted
          expect(result_lead.errors.full_messages).to include('Lead is being processed asynchronously')
          expect(creator.status).to eq(:async_processing)
        end.not_to(change { Lead.count })
      end
    end

    context 'with invalid token' do
      it 'returns error without creating lead' do
        creator = described_class.new(data: valid_lead_data, token: 'invalid_token')

        expect do
          result_lead = creator.call
          expect(result_lead).not_to be_persisted
          expect(result_lead.errors.full_messages).to include(/Invalid Access Token/)
        end.not_to(change { Lead.count })
      end
    end

    context 'with missing parser' do
      before do
        allow(described_class).to receive(:get_parser).and_return(nil)
      end

      it 'returns error without creating lead' do
        creator = described_class.new(data: valid_lead_data, token: lead_source.api_token)

        expect do
          result_lead = creator.call
          expect(result_lead).not_to be_persisted
          expect(result_lead.errors.full_messages).to include(/Parser for Lead Source not found/)
        end.not_to(change { Lead.count })
      end
    end

    context 'with resident validation' do
      let(:resident) { create(:resident, property: property, status: 'current') }
      let(:resident_detail) { create(:resident_detail, resident: resident) }

      before do
        # Mock all ENV calls properly
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with('ENABLE_OPENAI_PARSER', 'false').and_return('false')
      end

      context 'when lead matches resident by phone1' do
        before do
          resident_detail.update!(phone1: '5551234567')
        end

        it 'prevents lead creation and returns error' do
          creator = described_class.new(data: valid_lead_data, token: lead_source.api_token)

          expect do
            result_lead = creator.call
            expect(result_lead).not_to be_persisted
            expect(result_lead.errors.full_messages).to include(/This lead matches an existing resident.*phone: 5551234567/)
          end.not_to(change { Lead.count })
        end

        it 'creates an error note' do
          creator = described_class.new(data: valid_lead_data, token: lead_source.api_token)

          expect do
            creator.call
          end.to change { Note.where(classification: 'error').count }.by(1)

          error_note = Note.where(classification: 'error').last
          expect(error_note.content).to include('Leads::Creator blocked lead creation')
          expect(error_note.content).to include("matched resident ID: #{resident.id}")
        end
      end

      context 'when lead matches resident by email' do
        before do
          resident_detail.update!(email: 'john@example.com')
        end

        it 'prevents lead creation' do
          creator = described_class.new(data: valid_lead_data, token: lead_source.api_token)

          expect do
            result_lead = creator.call
            expect(result_lead).not_to be_persisted
            expect(result_lead.errors.full_messages).to include(/This lead matches an existing resident.*email: john@example.com/)
          end.not_to(change { Lead.count })
        end
      end


      context 'when lead has same name as resident but different contact info' do
        before do
          resident.update!(first_name: 'John', last_name: 'Doe')
          resident_detail.update!(phone1: '5559999999', email: 'different@example.com')
        end

        it 'allows lead creation' do
          creator = described_class.new(data: valid_lead_data, token: lead_source.api_token)

          expect do
            result_lead = creator.call
            expect(result_lead).to be_persisted
            expect(result_lead.errors).to be_empty
          end.to change { Lead.count }.by(1)
        end
      end

      context 'when lead does not match any resident' do
        before do
          resident.update!(first_name: 'Jane', last_name: 'Smith')
          resident_detail.update!(phone1: '5559999999', email: 'jane@example.com')
        end

        it 'allows lead creation' do
          creator = described_class.new(data: valid_lead_data, token: lead_source.api_token)

          expect do
            result_lead = creator.call
            expect(result_lead).to be_persisted
            expect(result_lead.errors).to be_empty
          end.to change { Lead.count }.by(1)
        end
      end

      context 'when lead has no property assigned' do
        let(:lead_data_without_property) do
          {
            first_name: 'John',
            last_name: 'Doe',
            email: 'john@example.com',
            phone1: '5551234567'
          }
        end

        before do
          resident_detail.update!(phone1: '5551234567')
        end

        it 'skips resident validation and creates lead with warning' do
          creator = described_class.new(data: lead_data_without_property, token: lead_source.api_token)

          expect do
            result_lead = creator.call
            expect(result_lead).to be_persisted
            expect(result_lead.notes).to include('COULD NOT IDENTIFY PROPERTY')
          end.to change { Lead.count }.by(1)
        end
      end

      context 'for phone source leads' do
        let(:phone_source) { create(:lead_source, slug: 'CallCenter') }
        let(:phone_listing) { create(:property_listing, property: property, source: phone_source, code: property.id) }

        before do
          phone_listing
          resident_detail.update!(phone1: '5551234567')
        end

        it 'blocks lead creation when matching resident (same as other sources)' do
          creator = described_class.new(data: valid_lead_data, token: phone_source.api_token)

          expect do
            result_lead = creator.call
            expect(result_lead).not_to be_persisted
            expect(result_lead.errors.full_messages).to include(/This lead matches an existing resident/)
          end.not_to(change { Lead.count })
        end

        it 'still checks for duplicate leads by phone after resident check passes' do
          # Create an existing lead with different contact info
          create(:lead, phone1: '5557777777', property: property)

          # Update lead data to not match resident but match existing lead
          phone_lead_data = valid_lead_data.merge(phone1: '5557777777')

          creator = described_class.new(data: phone_lead_data, token: phone_source.api_token)

          expect do
            result_lead = creator.call
            expect(result_lead).not_to be_persisted
            expect(result_lead.errors.full_messages).to include(/This lead matches the phone number of an existing recent lead/)
          end.not_to(change { Lead.count })
        end
      end
    end
  end

  describe 'status tracking' do
    before do
      # Mock all ENV calls properly
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('ENABLE_OPENAI_PARSER', 'false').and_return('false')
    end

    it 'tracks status from parser result' do
      creator = described_class.new(data: valid_lead_data, token: lead_source.api_token)
      creator.call

      expect(creator.status).to eq(:ok)
    end

    context 'with async processing' do
      let(:async_result) do
        Leads::Creator::Result.new(
          status: :async_processing,
          lead: {},
          errors: ActiveModel::Errors.new(Lead.new),
          property_code: property.id.to_s,
          parser: 'OpenAI (Async)'
        )
      end

      before do
        allow(described_class).to receive(:get_parser).and_return(Leads::Adapters::Bluesky)
        allow_any_instance_of(Leads::Adapters::Bluesky).to receive(:parse).and_return(async_result)
      end

      it 'tracks async_processing status' do
        creator = described_class.new(data: valid_lead_data, token: lead_source.api_token)
        creator.call

        expect(creator.status).to eq(:async_processing)
      end
    end
  end
end
