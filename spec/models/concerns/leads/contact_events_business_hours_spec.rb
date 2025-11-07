require 'rails_helper'

RSpec.describe Leads::ContactEvents, type: :model do
  describe '#contact_lead_time with business hours' do
    let(:property) do
      create(:property,
        timezone: 'Central Time (US & Canada)',
        working_hours: {
          'monday' => {
            'morning' => {'open' => '6:00 AM', 'close' => '12:00PM'},
            'afternoon' => {'open' => '1:00 PM', 'close' => '5:00 PM'}
          },
          'tuesday' => {
            'morning' => {'open' => '6:00 AM', 'close' => '12:00PM'},
            'afternoon' => {'open' => '1:00 PM', 'close' => '5:00 PM'}
          },
          'wednesday' => {
            'morning' => {'open' => '6:00 AM', 'close' => '12:00PM'},
            'afternoon' => {'open' => '1:00 PM', 'close' => '5:00 PM'}
          },
          'thursday' => {
            'morning' => {'open' => '6:00 AM', 'close' => '12:00PM'},
            'afternoon' => {'open' => '1:00 PM', 'close' => '5:00 PM'}
          },
          'friday' => {
            'morning' => {'open' => '6:00 AM', 'close' => '12:00PM'},
            'afternoon' => {'open' => '1:00 PM', 'close' => '5:00 PM'}
          },
          'saturday' => {
            'morning' => {'open' => nil, 'close' => nil},
            'afternoon' => {'open' => nil, 'close' => nil}
          },
          'sunday' => {
            'morning' => {'open' => nil, 'close' => nil},
            'afternoon' => {'open' => nil, 'close' => nil}
          }
        }
      )
    end

    context 'when lead is created and contacted during business hours' do
      it 'calculates lead time using only business hours elapsed' do
        # Lead created Monday at 9am CST
        created_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-06 09:00:00')
        # Contacted Monday at 11am CST (2 hours later)
        contact_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-06 11:00:00')

        lead = create(:lead, property: property, created_at: created_time, state: 'open', classification: nil)
        lead_time = lead.contact_lead_time(true, contact_time)

        # Should be 120 minutes
        expect(lead_time).to eq(120)
      end
    end

    context 'when lead is created outside business hours' do
      it 'starts timer when office opens' do
        # Lead created Monday at 8pm CST (outside business hours)
        created_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-06 20:00:00')
        # Contacted Tuesday at 7am CST (1 hour after office opens)
        contact_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-07 07:00:00')

        lead = create(:lead, property: property, created_at: created_time, state: 'open', classification: nil)
        lead_time = lead.contact_lead_time(true, contact_time)

        # Timer should start at 6am Tuesday, contacted at 7am = 60 minutes
        expect(lead_time).to eq(60)
      end
    end

    context 'when lead spans lunch break' do
      it 'excludes lunch hour from calculation' do
        # Lead created Monday at 11am CST
        created_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-06 11:00:00')
        # Contacted Monday at 2pm CST (3 hours later, including 1 hour lunch)
        contact_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-06 14:00:00')

        lead = create(:lead, property: property, created_at: created_time, state: 'open', classification: nil)
        lead_time = lead.contact_lead_time(true, contact_time)

        # Should be 11am-12pm (1hr) + 1pm-2pm (1hr) = 120 minutes
        expect(lead_time).to eq(120)
      end
    end

    context 'when lead spans multiple days' do
      it 'excludes nights and weekends' do
        # Lead created Monday at 4pm CST
        created_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-06 16:00:00')
        # Contacted Tuesday at 10am CST
        contact_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-07 10:00:00')

        lead = create(:lead, property: property, created_at: created_time, state: 'open', classification: nil)
        lead_time = lead.contact_lead_time(true, contact_time)

        # Monday: 4pm-5pm (1hr) = 60 min
        # Monday night: not counted
        # Tuesday: 6am-10am (4hrs) = 240 min
        # Total: 60 + 240 = 300 minutes
        expect(lead_time).to eq(300)
      end
    end

    context 'when elapsed time exceeds 48 hours' do
      it 'uses simple calculation instead of business hours' do
        # Lead created 4 days ago
        created_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-02 09:00:00')
        # Contacted today
        contact_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-06 09:00:00')

        lead = create(:lead, property: property, created_at: created_time, state: 'open', classification: nil)
        lead_time = lead.contact_lead_time(true, contact_time)

        # Should use simple calculation: 4 days = 5760 minutes
        expect(lead_time).to eq(5760)
      end
    end

    context 'when lead has no property' do
      it 'falls back to simple calculation' do
        created_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-03 20:00:00')
        contact_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-06 08:00:00')

        lead = create(:lead, property: nil, created_at: created_time, state: 'open', classification: nil)
        lead_time = lead.contact_lead_time(true, contact_time)

        # Should use simple calculation (roughly 60 hours = 3600 minutes)
        expect(lead_time).to be > 3500
        expect(lead_time).to be < 3700
      end
    end

    context 'when business hours calculation fails' do
      it 'falls back to simple calculation and logs warning' do
        created_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-06 09:00:00')
        contact_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-06 11:00:00')

        lead = create(:lead, property: property, created_at: created_time, state: 'open', classification: nil)

        # Simulate failure in working_hours_difference_in_time
        allow(property).to receive(:working_hours_difference_in_time).and_raise(StandardError.new('Test error'))
        allow(Rails.logger).to receive(:warn)

        lead_time = lead.contact_lead_time(true, contact_time)

        # Should fall back to simple calculation: 2 hours = 120 minutes
        expect(lead_time).to eq(120)
        expect(Rails.logger).to have_received(:warn).with(/Failed to calculate business hours/)
      end
    end

    context 'phone-sourced leads' do
      it 'maintains automatic 0-minute lead time' do
        source = create(:lead_source, slug: 'Arrowtel')  # Valid phone source
        user = create(:user)
        created_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-03 20:00:00')
        lead = create(:lead,
          property: property,
          source: source,
          user: user,
          created_at: created_time,
          state: 'open',
          classification: nil
        )

        # Phone leads get automatic contact event with lead_time: 0
        # Reload to get the contact event created by after_create callback
        lead.reload
        expect(lead.contact_events.first_contact.count).to eq(1)
        expect(lead.contact_events.first_contact.first.lead_time).to eq(0)
      end
    end

    context 'edge cases' do
      it 'returns minimum 1 minute for very quick responses' do
        # Lead created and contacted almost immediately during business hours
        created_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-06 09:00:00')
        contact_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-06 09:00:30') # 30 seconds later

        lead = create(:lead, property: property, created_at: created_time, state: 'open', classification: nil)
        lead_time = lead.contact_lead_time(true, contact_time)

        # Should be minimum 1 minute
        expect(lead_time).to eq(1)
      end

      it 'handles contact before creation (edge case)' do
        created_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-06 09:00:00')
        contact_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-06 08:00:00') # Before creation

        lead = create(:lead, property: property, created_at: created_time, state: 'open', classification: nil)
        lead_time = lead.contact_lead_time(true, contact_time)

        # Should return minimum 1 minute
        expect(lead_time).to eq(1)
      end
    end

    context 'integration with create_contact_event' do
      it 'uses business hours when creating first contact event' do
        # Lead created Monday at 8pm CST
        created_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-06 20:00:00')
        lead = create(:lead, property: property, created_at: created_time, state: 'open', classification: nil)

        # Contact made Tuesday at 7am CST
        contact_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-07 07:00:00')

        event = lead.create_contact_event({
          timestamp: contact_time,
          description: 'Test contact'
        })

        # Should have business hours lead time (60 minutes)
        expect(event.lead_time).to eq(60)
        expect(event.first_contact).to be true
      end

      it 'applies business hours to scheduled action contact events' do
        created_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-06 09:00:00')
        lead = create(:lead, property: property, created_at: created_time, state: 'open', classification: nil)

        lead_action = create(:lead_action, is_contact: true)
        scheduled_action = create(:scheduled_action,
          target: lead,
          lead_action: lead_action,
          completed_at: ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-06 11:00:00')
        )

        event = lead.create_scheduled_action_contact_event(scheduled_action)

        # Should have business hours lead time (120 minutes)
        expect(event.lead_time).to eq(120)
      end
    end

    context 'grading scale verification' do
      it 'achieves Grade A with quick business hours response' do
        created_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-06 09:00:00')
        contact_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-06 09:20:00') # 20 minutes

        lead = create(:lead, property: property, created_at: created_time, state: 'open', classification: nil)
        lead.create_contact_event({
          timestamp: contact_time,
          description: 'Quick response'
        })

        expect(lead.lead_speed).to eq('A')
      end

      it 'achieves Grade B with moderate business hours response' do
        created_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-06 09:00:00')
        contact_time = ActiveSupport::TimeZone['Central Time (US & Canada)'].parse('2025-01-06 10:30:00') # 90 minutes

        lead = create(:lead, property: property, created_at: created_time, state: 'open', classification: nil)
        lead.create_contact_event({
          timestamp: contact_time,
          description: 'Moderate response'
        })

        expect(lead.lead_speed).to eq('B')
      end
    end
  end
end
