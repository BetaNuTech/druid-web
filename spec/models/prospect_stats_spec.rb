require 'rails_helper'

RSpec.describe ProspectStats do

  describe "returning statistics" do
    include_context "users"
    include_context "messaging"

    let(:cobalt_source) { create(:cobalt_source) }
    let(:voyager_source) { create(:yardi_voyager_source) }
    let(:source) { create(:lead_source, slug: LeadSource::DEFAULT_SLUG) }
    let(:source2) { create(:lead_source, slug: 'source2') }
    let(:property) { create(:property) }
    let(:property2) { create(:property) }
    let(:property3) { create(:property) }
    let(:listing) { create(:property_listing, source_id: source.id, property_id: property.id) }
    let(:listing2) { create(:property_listing, source_id: source.id, property_id: property2.id) }
    let(:listing3) { create(:property_listing, source_id: source2.id, property_id: property3.id) }

    let(:lead1) { create(:lead, property: property, source: source, state: 'open') }
    let(:lead2) { create(:lead, property: property2, source: source, state: 'open') }
    let(:lead3) { create(:lead, property: property, source: source2) }
    let(:lead4) { create(:lead, property: property2, source: source2) }

    before do
      lead1; lead2; lead3; lead4
      lead1.trigger_event(event_name: 'work', user: agent)
      lead2.trigger_event(event_name: 'work', user: agent)
      listing; listing2; listing3
      cobalt_source; voyager_source
    end

    it "refreshes the cache" do
      stats = ProspectStats.new
      stats.refresh_cache
      stats.caching = false
      stats.property_stats
    end

  end

  describe "#prospect_count duplicate handling" do
    let(:property) { create(:property) }
    let(:source) { create(:lead_source) }
    let(:stats) { ProspectStats.new }

    before do
      # Create Yardi Voyager source needed by ProspectStats
      create(:lead_source, slug: 'YardiVoyager')
      # Disable caching for tests
      stats.caching = false
      # Set a consistent end date for tests
      allow(stats).to receive(:end_date).and_return(DateTime.current)
    end

    context "with no duplicates" do
      it "counts each lead as a separate prospect" do
        lead_a = create(:lead, property: property, source: source, state: 'open', first_comm: 1.day.ago)
        lead_b = create(:lead, property: property, source: source, state: 'open', first_comm: 2.days.ago)
        lead_c = create(:lead, property: property, source: source, state: 'open', first_comm: 3.days.ago)

        # Create initial transitions for each lead
        create(:lead_transition, lead: lead_a, last_state: 'new', current_state: 'open')
        create(:lead_transition, lead: lead_b, last_state: 'new', current_state: 'open')
        create(:lead_transition, lead: lead_c, last_state: 'new', current_state: 'open')

        # No duplicate relationships
        expect(stats.send(:prospect_count, property, 30)).to eq(3)
      end
    end

    context "with a simple pair of duplicates" do
      it "counts the pair as one prospect" do
        lead_a = create(:lead, property: property, source: source, state: 'open', first_comm: 1.day.ago)
        lead_b = create(:lead, property: property, source: source, state: 'open', first_comm: 2.days.ago)
        lead_c = create(:lead, property: property, source: source, state: 'open', first_comm: 3.days.ago)

        # Create initial transitions
        create(:lead_transition, lead: lead_a, last_state: 'new', current_state: 'open')
        create(:lead_transition, lead: lead_b, last_state: 'new', current_state: 'open')
        create(:lead_transition, lead: lead_c, last_state: 'new', current_state: 'open')

        # Mark A and B as duplicates (bidirectional relationship)
        DuplicateLead.create(reference_id: lead_a.id, lead_id: lead_b.id)
        DuplicateLead.create(reference_id: lead_b.id, lead_id: lead_a.id)

        # Should count as 2 prospects: (A-B cluster) + C
        expect(stats.send(:prospect_count, property, 30)).to eq(2)
      end
    end

    context "with a triple cluster" do
      it "correctly counts three duplicates as one prospect" do
        lead_a = create(:lead, property: property, source: source, state: 'open', first_comm: 1.day.ago)
        lead_b = create(:lead, property: property, source: source, state: 'open', first_comm: 2.days.ago)
        lead_c = create(:lead, property: property, source: source, state: 'open', first_comm: 3.days.ago)

        # Create initial transitions
        create(:lead_transition, lead: lead_a, last_state: 'new', current_state: 'open')
        create(:lead_transition, lead: lead_b, last_state: 'new', current_state: 'open')
        create(:lead_transition, lead: lead_c, last_state: 'new', current_state: 'open')

        # Mark all three as duplicates of each other
        # This simulates what mark_duplicates would create
        DuplicateLead.create(reference_id: lead_a.id, lead_id: lead_b.id)
        DuplicateLead.create(reference_id: lead_a.id, lead_id: lead_c.id)
        DuplicateLead.create(reference_id: lead_b.id, lead_id: lead_a.id)
        DuplicateLead.create(reference_id: lead_b.id, lead_id: lead_c.id)
        DuplicateLead.create(reference_id: lead_c.id, lead_id: lead_a.id)
        DuplicateLead.create(reference_id: lead_c.id, lead_id: lead_b.id)

        # Should count as 1 prospect (all in one cluster)
        expect(stats.send(:prospect_count, property, 30)).to eq(1)
      end
    end

    context "with multiple clusters" do
      it "correctly counts each cluster as one prospect" do
        # Create 6 leads
        leads = 6.times.map do |i|
          create(:lead, property: property, source: source, state: 'open', first_comm: (i+1).days.ago)
        end

        # Create initial transitions
        leads.each do |lead|
          create(:lead_transition, lead: lead, last_state: 'new', current_state: 'open')
        end

        # Create two clusters: (0-1) and (2-3), with 4 and 5 as singles
        DuplicateLead.create(reference_id: leads[0].id, lead_id: leads[1].id)
        DuplicateLead.create(reference_id: leads[1].id, lead_id: leads[0].id)
        DuplicateLead.create(reference_id: leads[2].id, lead_id: leads[3].id)
        DuplicateLead.create(reference_id: leads[3].id, lead_id: leads[2].id)

        # Should count as 4 prospects: (0-1 cluster) + (2-3 cluster) + 4 + 5
        expect(stats.send(:prospect_count, property, 30)).to eq(4)
      end
    end

    context "with a large cluster of 5 duplicates" do
      it "correctly counts all five as one prospect" do
        # Create 5 leads that are all duplicates
        leads = 5.times.map do |i|
          create(:lead, property: property, source: source, state: 'open', first_comm: (i+1).days.ago)
        end

        # Create initial transitions
        leads.each do |lead|
          create(:lead_transition, lead: lead, last_state: 'new', current_state: 'open')
        end

        # Mark all as duplicates of each other (full mesh)
        leads.each do |reference_lead|
          leads.each do |duplicate_lead|
            next if reference_lead == duplicate_lead
            DuplicateLead.create(reference_id: reference_lead.id, lead_id: duplicate_lead.id)
          end
        end

        # Should count as 1 prospect (all in one cluster)
        expect(stats.send(:prospect_count, property, 30)).to eq(1)
      end
    end

    context "with transitive duplicates" do
      it "correctly identifies transitive relationships through the graph" do
        # Create 4 leads where A-B and B-C are duplicates (making A-C transitive)
        lead_a = create(:lead, property: property, source: source, state: 'open', first_comm: 1.day.ago)
        lead_b = create(:lead, property: property, source: source, state: 'open', first_comm: 2.days.ago)
        lead_c = create(:lead, property: property, source: source, state: 'open', first_comm: 3.days.ago)
        lead_d = create(:lead, property: property, source: source, state: 'open', first_comm: 4.days.ago)

        # Create initial transitions
        create(:lead_transition, lead: lead_a, last_state: 'new', current_state: 'open')
        create(:lead_transition, lead: lead_b, last_state: 'new', current_state: 'open')
        create(:lead_transition, lead: lead_c, last_state: 'new', current_state: 'open')
        create(:lead_transition, lead: lead_d, last_state: 'new', current_state: 'open')

        # Create chain: A-B, B-C (making A-B-C a connected cluster)
        DuplicateLead.create(reference_id: lead_a.id, lead_id: lead_b.id)
        DuplicateLead.create(reference_id: lead_b.id, lead_id: lead_a.id)
        DuplicateLead.create(reference_id: lead_b.id, lead_id: lead_c.id)
        DuplicateLead.create(reference_id: lead_c.id, lead_id: lead_b.id)

        # Should count as 2 prospects: (A-B-C cluster) + D
        expect(stats.send(:prospect_count, property, 30)).to eq(2)
      end
    end

    context "with partial visibility in time window" do
      it "only counts duplicates that are within the time window" do
        # Create leads with different timestamps
        lead_a = create(:lead, property: property, source: source, state: 'open', first_comm: 5.days.ago)
        lead_b = create(:lead, property: property, source: source, state: 'open', first_comm: 10.days.ago)
        lead_c = create(:lead, property: property, source: source, state: 'open', first_comm: 35.days.ago) # Outside 30-day window

        # Create initial transitions
        create(:lead_transition, lead: lead_a, last_state: 'new', current_state: 'open')
        create(:lead_transition, lead: lead_b, last_state: 'new', current_state: 'open')
        create(:lead_transition, lead: lead_c, last_state: 'new', current_state: 'open')

        # All three are duplicates of each other
        DuplicateLead.create(reference_id: lead_a.id, lead_id: lead_b.id)
        DuplicateLead.create(reference_id: lead_a.id, lead_id: lead_c.id)
        DuplicateLead.create(reference_id: lead_b.id, lead_id: lead_a.id)
        DuplicateLead.create(reference_id: lead_b.id, lead_id: lead_c.id)
        DuplicateLead.create(reference_id: lead_c.id, lead_id: lead_a.id)
        DuplicateLead.create(reference_id: lead_c.id, lead_id: lead_b.id)

        # Only A and B are in the 30-day window, and they're connected, so count as 1
        expect(stats.send(:prospect_count, property, 30)).to eq(1)
      end
    end
  end

end
