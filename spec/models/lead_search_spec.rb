require 'rails_helper'

RSpec.describe LeadSearch do
  include_context "messaging"
  let(:empty_params) {
    {
      user_ids: [],
      property_ids: [],
      priorities: [],
      states: [],
      lead_last_name: nil,
      lead_first_name: nil,
      lead_id_number: nil,
      page: nil,
      per_page: nil,
      sort_by: nil,
      sort_dir: nil
    }
  }

  describe "initialization" do
    let(:minimal_instance) { LeadSearch.new(empty_params) }

    it "can be without a scope" do
      search = LeadSearch.new(empty_params)
      assert search.options.is_a?(Hash)
    end

    it "can be with a scope" do
      search = LeadSearch.new(empty_params, Lead)
      assert search.options.is_a?(Hash)
    end

    it "can be without any arguments" do
      search = LeadSearch.new
      assert search.options.is_a?(Hash)
    end
  end

  describe "returns a collection of Leads according to options" do
    include_context "users"
    let(:lead_source1) { create(:lead_source) }
    let(:lead_source2) { create(:lead_source) }

    let(:lead1) {
      create(:lead,
             state: 'prospect', priority: 'medium', first_name: "AaaBBbCC", last_name: "DdEeFFGgJJ",
             user: agent,
             property: property1,
             source: lead_source1,
             first_comm: 1.day.ago,
             vip: false
            )
    }

    let(:lead2) {
      create(:lead,
             state: 'disqualified', priority: 'low', id_number: "11223344",
             property: property2,
             source: lead_source2,
             first_comm: 2.days.ago,
             vip: true
            )
    }

    let(:lead3) { create(:lead, state: 'open', priority: 'high', first_comm: 3.days.ago, vip: false) }

    let(:property1) { create(:property) }
    let(:property2) { create(:property) }
    let(:property3) { create(:property) }

    before do
      lead1;lead2;lead3
    end

    it "returns a collection of leads" do
      search = LeadSearch.new(empty_params)
      expect(search.collection.count).to eq(Lead.count)
    end

    it "searches by source" do
      search = LeadSearch.new({sources: [lead_source1.id]})
      expect(search.collection.count).to eq(1)
      expect(search.collection.to_a).to eq([lead1])
    end

    it "searches by agent" do
      search = LeadSearch.new({user_ids: [agent.id]})
      expect(search.collection.to_a).to eq([lead1])
    end

    it "searches by state" do
      search = LeadSearch.new({states: ['prospect', 'disqualified']})
      expect(search.collection.to_a.sort).to eq([lead2, lead1].sort)
    end

    it "searches by priority" do
      search = LeadSearch.new({priorities: ['medium', 'high']})
      expect(search.collection.to_a.sort).to eq([lead1, lead3].sort)
    end

    it "searches by property" do
      search = LeadSearch.new({property_ids: [property1.id]})
      expect(search.collection.to_a).to eq([lead1])
    end

    it "searches by last name (case insensitive)" do
      search = LeadSearch.new({last_name: "jj"})
      expect(search.collection.to_a).to eq([lead1])
    end

    it "searches by first name (case insensitive)" do
      search = LeadSearch.new({first_name: "bbb"})
      expect(search.collection.to_a).to eq([lead1])
    end

    it "searches by DL/ID" do
      search = LeadSearch.new({id_number: "11223344"})
      expect(search.collection.to_a).to eq([lead2])
    end

    it "searches with text" do
      search = LeadSearch.new({text: "11223344"})
      expect(search.collection.to_a).to eq([lead2])
    end

    it "searches by vip" do
      search = LeadSearch.new({vip: "vip"})
      expect(search.collection.to_a).to eq([lead2])
      search = LeadSearch.new
      expect(search.collection.size).to eq(3)
    end

    it "searches by date" do
      date_format = "%Y-%m-%d"
      search = LeadSearch.new(
        { start_date: ( lead3.first_comm - 2.days ).strftime(date_format),
          end_date: ( lead3.first_comm - 1.days).strftime(date_format)})
      expect(search.collection.to_a).to be_empty
      search = LeadSearch.new(
        { start_date: ( lead3.first_comm - 1.hour ).strftime(date_format),
          end_date: ( lead2.first_comm + 1.hour).strftime(date_format)})
      expect(search.collection.to_a.map(&:id).sort).to eq([lead2,lead3].map(&:id).sort)
      search = LeadSearch.new( { start_date: 5.days.ago.strftime(date_format) })
      expect(search.collection.to_a.sort).to eq([lead1, lead2, lead3].sort)
      search = LeadSearch.new( { end_date: (lead3.first_comm + 1.hour).strftime(date_format) })
      expect(search.collection.to_a).to eq([lead3])
    end

    describe "options" do
      it "are returned by full_options" do
        property = create(:property)
        user = create(:user)
        search = LeadSearch.new({ user_ids: [User.first.id],
                                  property_ids: [Property.first.id],
                                  priorities: ["low"],
                                  states: ["open"],
                                  first_name: "foo",
                                  last_name: "foo",
                                  id_number: "11223344",
                                  sources: [LeadSource.first.id],
                                  text: ["foo"]
                                })
        expect(search.full_options).to be_a(Hash)
      end

    end

    describe "order" do
      it "is sorted by priority" do
        search = LeadSearch.new({sort_by: 'priority', sort_dir: 'desc'})
        expect(search.collection.to_a.map(&:id)).to eq([lead3, lead1, lead2].map(&:id))
        search = LeadSearch.new({sort_by: 'priority', sort_dir: 'asc'})
        expect(search.collection.to_a).to eq([lead2, lead1, lead3])
      end

      it "is sorted by most recent" do
        search = LeadSearch.new({sort_by: 'first_contact', sort_dir: 'asc'})
        expect(search.collection.to_a).to eq([lead3, lead2, lead1])
      end

      it "is sorted by lead name" do
        search = LeadSearch.new({sort_by: 'lead_name', sort_dir: 'asc'})
        expect(search.collection.map(&:last_name)).to eq([lead1, lead2, lead3].map(&:last_name).sort)
      end

    end

    describe "pagination" do

      before do
        10.times{ create(:lead, state: 'open')}
      end

      it "returns record_count" do
        search = LeadSearch.new({per_page: 3, page: 1})
        expect(search.record_count).to eq(Lead.count)
      end

      it "returns total_pages" do
        search = LeadSearch.new({per_page: 3, page: 1})
        expect(search.total_pages).to eq(5)
      end

      it "returns next_page_options" do
        current_page = 2
        search = LeadSearch.new({per_page: 3, page: current_page, states: ['open']})
        opts = search.next_page_options
        expect(opts[:states]).to eq(['open'])
        expect(opts[:page]).to eq(current_page + 1)

        # Next page of last page is last page
        search = LeadSearch.new({per_page: 3, page: 4, states: ['open']})
        opts = search.next_page_options
        expect(opts[:page]).to eq(search.total_pages)
      end

      it "returns previous_page_options" do
        current_page = 2
        search = LeadSearch.new({per_page: 3, page: current_page, states: ['open']})
        opts = search.previous_page_options
        expect(opts[:states]).to eq(['open'])
        expect(opts[:page]).to eq(current_page - 1)

        # Previous page of page 1 is 1
        search = LeadSearch.new({per_page: 3, page: 1, states: ['open']})
        expect(opts[:page]).to eq(1)
      end

      it "returns first_page_options" do
        current_page = 2
        search = LeadSearch.new({per_page: 3, page: current_page, states: ['open']})
        opts = search.first_page_options
        expect(opts[:states]).to eq(['open'])
        expect(opts[:page]).to eq(1)
      end

      it "returns last_page_options" do
        current_page = 2
        search = LeadSearch.new({per_page: 3, page: current_page, states: ['open']})
        opts = search.last_page_options
        expect(opts[:states]).to eq(['open'])
        expect(opts[:page]).to eq(search.total_pages)
      end

      it "returns the current_page" do
        current_page = 2
        search = LeadSearch.new({per_page: 3, page: current_page, states: ['open']})
        expect(search.current_page).to eq(current_page)
      end

      it "should return page_options" do
        current_page = 2
        new_page = 4
        search = LeadSearch.new({per_page: 3, page: current_page, states: ['open']})
        opts = search.page_options(new_page)
        expect(opts[:page]).to eq(new_page)
      end
    end

  end

end
