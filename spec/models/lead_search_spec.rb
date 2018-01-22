require 'rails_helper'

RSpec.describe LeadSearch do
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

    let(:lead1) {
      create(:lead,
             state: 'claimed', priority: 'low', first_name: "AaaBBbCC", last_name: "DdEeFFGgJJ",
             user: agent,
             property: property1,
            )
    }

    let(:lead2) {
      create(:lead,
             state: 'disqualified', priority: 'medium', id_number: "11223344",
             property: property2
            )
    }

    let(:lead3) { create(:lead, state: 'open', priority: 'high') }

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

    it "searches by agent" do
      search = LeadSearch.new({user_ids: [agent.id]})
      expect(search.collection.to_a).to eq([lead1])
    end

    it "searches by state" do
      search = LeadSearch.new({states: ['claimed', 'disqualified']})
      expect(search.collection.to_a).to eq([lead1, lead2])
    end

    it "searches by priority" do
      search = LeadSearch.new({priorities: ['medium', 'high']})
      expect(search.collection.to_a).to eq([lead2, lead3])
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

    describe "order" do
      it "is sorted by priority" do
        search = LeadSearch.new({sort_by: 'priority', sort_dir: 'desc'})
        expect(search.collection.to_a.map(&:id)).to eq([lead3, lead2, lead1].map(&:id))
        search = LeadSearch.new({sort_by: 'priority', sort_dir: 'asc'})
        expect(search.collection.to_a).to eq([lead1, lead2, lead3])
      end

      it "is sorted by most recent" do
        search = LeadSearch.new({sort_by: 'recent', sort_dir: 'desc'})
        expect(search.collection.to_a).to eq([lead3, lead2, lead1])
      end

      it "is sorted by lead name" do
        search = LeadSearch.new({sort_by: 'lead_name', sort_dir: 'asc'})
        expect(search.collection.map(&:last_name)).to eq([lead1, lead2, lead3].map(&:last_name).sort)
      end

    end

    describe "pagination" do

      before do
        10.times{ create(:lead)}
      end

      it "returns record_count" do
        search = LeadSearch.new({per_page: 3, page: 1})
        expect(search.record_count).to eq(Lead.count)
      end

      it "returns total_pages" do
        search = LeadSearch.new({per_page: 3, page: 1})
        expect(search.total_pages).to eq(4)
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
    end

  end

end
