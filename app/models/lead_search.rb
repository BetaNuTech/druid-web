class LeadSearch
  ALLOWED_PARAMS = [ :user_ids, :property_ids, :priorities, :states, :sources, :referrals, :last_name, :first_name, :id_number, :text, :page, :per_page, :sort_by, :sort_dir, :start_date, :end_date, :bedrooms, :vip]
  LEAD_TABLE = Lead.table_name
  DEFAULT_PER_PAGE = 10
  MAX_PER_PAGE = 100
  DEFAULT_SORT = [:priority, :desc]
  DEFAULT_START_DATE = 99.years.ago
  SORT_OPTIONS = {
    priority: {
      asc: "#{LEAD_TABLE}.priority ASC, #{LEAD_TABLE}.first_comm ASC",
      desc: "#{LEAD_TABLE}.priority DESC, #{LEAD_TABLE}.first_comm DESC" },
    first_contact: {
      asc: "#{LEAD_TABLE}.first_comm ASC",
      desc: "#{LEAD_TABLE}.first_comm DESC" },
    last_contact: {
      asc: "COALESCE(#{LEAD_TABLE}.last_comm, #{LEAD_TABLE}.first_comm) ASC",
      desc: "COALESCE(#{LEAD_TABLE}.last_comm, #{LEAD_TABLE}.first_comm) DESC" },
    lead_name: {
      asc: "#{LEAD_TABLE}.last_name ASC, #{LEAD_TABLE}.first_name ASC",
      desc: "#{LEAD_TABLE}.last_name DESC, #{LEAD_TABLE}.first_name DESC" }
  }

  attr_reader :options, :skope

  def initialize(options={}, skope=Lead, user=nil)
    @default_skope = skope
    @options = process_options(options)
    @skope = @default_skope
    @filter_applied = false
    @perform_sort = true
    @user = user
  end


  def collection
    query_skope.skope
  end

  def query_skope
    filtered_skope = self.
      filter_by_source.
      filter_by_referral.
      filter_by_state.
      filter_by_priority.
      filter_by_vip.
      filter_by_user.
      filter_by_property.
      filter_by_first_name.
      filter_by_last_name.
      filter_by_id_number.
      filter_by_date.
      filter_by_bedrooms.
      search_by_text

    if @perform_sort
      return filtered_skope.sort
    else
      return filtered_skope
    end
  end


  def full_options
    opts = {
      "Filters" => {
        "_index" => ["Start Date", "End Date", "Vip", "Agents", "Properties", "Priorities", "States", "Referrals", "Sources", "First Name", "Last Name", "ID Number", "Search", "Bedrooms"],
        "Vip" => {
          param: "vip",
          type: "select",
          values: vip_values,
          options: [{label: 'Yes', value: 'vip'}, {label: 'No', value: 'notvip' }]
        },
        "Agents" => {
          param: "user_ids",
          type: "select",
          values: User.where(id: @options[:user_ids]).map{|u| {label: u.name, value: u.id}},
          options: agent_options
        },
        "Properties" => {
          param: "property_ids",
          type: "select",
          values: property_values,
          options: property_options
        },
        "Priorities" => {
          param: "priorities",
          type: "select",
          values: Lead.priorities.select{|k,v| Array(@options[:priorities]).include?(v.to_s) }.map{|p| {label: p[0].capitalize, value: p[1].to_s}},
          options: Lead.priorities.map{|p| {label: p[0].capitalize, value: p[1].to_s}}
        },
        "States" => {
          param: "states",
          type: "select",
          values: Array(@options[:states]).map{|s| {label: s.capitalize, value: s}},
          options: Lead.state_names.map{|s| {label: s.humanize, value: s}}
        },
        "Sources" => {
          param: "sources",
          type: "select",
          values: LeadSource.where(id: @options[:sources]).map{|s| {label: s.name, value: s.id}},
          options: LeadSource.active.map{|s| {label: s.name, value: s.id}}
        },
        "Referrals" => {
          param: "referrals",
          type: "select",
          values: Array(@options[:referrals]).map{|r| {label: r, value: r}},
          options: Lead.select("distinct(referral)").order("referral ASC").
            map{|r| {label: r.referral, value: r.referral}}.
            select{|r| r[:label].present? && r[:label] != 'Null' }
        },
        "First Name" => {
          param: "first_name",
          type: "text",
          values: Array(@options[:first_name]).map{|v| {label: v, value: v} },
          options: []
        },
        "Last Name" => {
          param: "last_name",
          type: "text",
          values: Array(@options[:last_name]).map{|v| {label: v, value: v} },
          options: []
        },
        "ID Number" => {
          param: "id_number",
          type: "text",
          values: Array(@options[:id_number]).map{|v| {label: v, value: v} },
          options: []
        },
        "Search" => {
          param: "text",
          type: "text",
          values: Array(@options[:text]),
          options: []
        },
        "Start Date" => {
          param: "start_date",
          type: "date",
          values: Array(@options[:start_date]),
          options: []
        },
        "End Date" => {
          param: "end_date",
          type: "date",
          values: Array(@options[:end_date]),
          options: []
        },
        "Bedrooms" => {
          param: "bedrooms",
          type: "select",
          values: Array(@options[:bedrooms]).map{|v| {label: v, value: v}},
          options: bedroom_options
        },
      },
      "Pagination" => {
        "_index" => ["Page", "PerPage", "SortBy", "SortDir"],
        "_total_pages" => total_pages,
        "Page" => {
          param: "page",
          values: [ {label: "Page", value: query_page} ]
        },
        "PerPage" => {
          param: "per_page",
          values: [{ label: "Per Page", value: query_limit }]
        },
        "SortBy" => {
          param: "sort_by",
          values: [ { label: "Sort By", value: query_sort_by }],
          options: [ {label: 'Priority', value: 'priority'},
                     {label: 'First Contact', value: 'first_contact'},
                     {label: 'Last Contact', value: 'last_contact'},
                     {label: 'Name', value: 'lead_name'} ]
        },
        "SortDir" => {
          param: "sort_dir",
          values: [ { label: "Sort Direction", value: query_sort_dir }],
          options: [ {label: 'Ascending', value: 'asc'}, {label: 'Descending', value: 'desc'} ]
        }
      }
    }
  end

  def paginated
    self.query_skope.paginate
  end

  def current_page
    return query_page
  end

  def record_count
    self.collection.count
  end

  def total_pages
    [ ( (record_count / query_limit).ceil + 1 ), 1 ].max
  end

  def page_options(page)
    opts = @options.dup
    opts[:page] = page.to_i
    return opts
  end

  def next_page_options
    opts = @options.dup
    next_page = (opts[:page] || 0).to_i + 1
    opts[:page] = [next_page, total_pages].min
    return opts
  end

  def previous_page_options
    opts = @options.dup
    previous_page = [1, ( (opts[:page] || 0).to_i - 1 ) ].max
    opts[:page] = previous_page
    return opts
  end

  def first_page_options
    opts = @options.dup
    opts[:page] = 1
    return opts
  end

  def last_page_options
    opts = @options.dup
    opts[:page] = total_pages
    return opts
  end

  def filter_by_date(start_date=nil, end_date=nil)
    start_date ||= @options[:start_date]
    end_date ||= @options[:end_date]
    end_date = Array(end_date).compact.first
    if ( start_date || end_date ).present?
      if start_date.present?
        start_date = Array(start_date).compact.first
        if start_date.is_a?(String)
          start_date = DateTime.parse(start_date).beginning_of_day rescue nil
        else
          start_date = start_date.beginning_of_day
        end
      end
      if end_date.present?
        if end_date.is_a?(String)
          end_date = DateTime.parse(end_date).end_of_day rescue nil
        else
          end_date = end_date.end_of_day
        end
      end
      @skope = @skope.
        where(first_comm: ( start_date || DEFAULT_START_DATE )..( end_date || DateTime.current ))
      @filter_applied = true
    end
    return self
  end

  def filter_by_state(states=nil)
    states ||= @options[:states]
    if states.present?
      @skope = @skope.
        where(state: states)
      @filter_applied = true
    end
    return self
  end

  def filter_by_priority(priorities=nil)
    priorities ||= @options[:priorities]
    if priorities.present?
      priority_list = priorities.compact.map(&:to_sym)
      @skope = @skope.
        where(priority: priority_list)
      @filter_applied = true
    end
    return self
  end

  def filter_by_vip(vip=nil)
    vip_options = vip || @options[:vip]
    vip_options = Array(vip_options) unless vip_options.is_a?(Array)
    return self if vip_options.blank?

    vip_options.map!(&:to_sym)
    vip = vip_options.include?(:vip)
    notvip = vip_options.include?(:notvip)

    # No filter if both are set or both are unset
    return self if ( vip && notvip ) || ( !vip && !notvip )

    is_vip = vip ? true : !notvip

    @skope = @skope.where(vip: is_vip)
    @filter_applied = true
    return self
  end

  def filter_by_user(user_ids=nil)
    user_ids ||= @options[:user_ids]
    if user_ids.present?
      @skope = @skope.
        includes(:user).
        where(users: {id: user_ids})
      @filter_applied = true
    end
    return self
  end

  def filter_by_property(property_ids=nil)
    property_ids ||= @options[:property_ids]
    if property_ids.present?
      @skope = @skope.
        where(property_id: property_ids)
      @filter_applied = true
    end
    return self
  end

  def filter_by_first_name(first_name=nil)
    first_name ||= @options[:first_name]
    first_name = first_name.first if first_name.is_a?(Array)
    if first_name.present?
      @skope = @skope.
        where("#{LEAD_TABLE}.first_name ILIKE ?", "%#{first_name}%")
      @filter_applied = true
    end
    return self
  end

  def filter_by_last_name(last_name=nil)
    last_name ||= @options[:last_name]
    last_name = last_name.last if last_name.is_a?(Array)
    if last_name.present?
      @skope = @skope.
        where("#{LEAD_TABLE}.last_name ILIKE ?", "%#{last_name}%")
      @filter_applied = true
    end
    return self
  end

  def filter_by_id_number(id_number=nil)
    id_number ||= @options[:id_number]
    id_number = id_number.first if id_number.is_a?(Array)
    if id_number.present?
      @skope = @skope.
        where(id_number: id_number)
      @filter_applied = true
    end
    return self
  end

  def filter_by_source(sources=nil)
    sources ||= @options[:sources]
    if sources.present?
      @skope = @skope.
        where(lead_source_id: sources)
      @filter_applied = true
    end
    return self
  end

  def filter_by_referral(referrals=nil)
    referrals ||= @options[:referrals]
    if referrals.present?
      @skope = @skope.
        includes(:preference).
        where(referral: referrals)
      @filter_applied = true
    end
    return self
  end

  def search_by_text(text=nil)
    text ||= @options[:text]
    text = text.first if text.is_a?(Array)
    if text.present?
      @skope = @skope.
        search_for(text)
      @perform_sort = false
    end
    return self
  end

  def filter_by_bedrooms(bedrooms=nil)
    bedrooms ||= @options[:bedrooms]
    if bedrooms.present?
      @skope = @skope.
        includes(:preference).
        where(lead_preferences: {beds: bedrooms})
      @filter_applied = true
    end
    return self
  end

  def paginate
    @skope.limit(query_limit).offset(query_offset)
  end

  def sort
    @skope = @skope.order(Arel.sql(query_sort))
    return self
  end

  private

  def process_options(options)
    out = (options || {})
    out = options.to_unsafe_h unless options.is_a?(Hash)
    out[:vip] = normalize_vip_options(out[:vip])
    out
  end

  def normalize_vip_options(options)
    # TODO
    options
  end

  def query_sort
    SORT_OPTIONS.fetch(query_sort_by).fetch(query_sort_dir)
  end

  def query_limit
    per_page = Array(@options[:per_page] || nil).first || DEFAULT_PER_PAGE
    [per_page.to_i, MAX_PER_PAGE].min
  end

  def query_offset
    query_page * query_limit - query_limit
  end

  def query_page
    page_number = Array(@options[:page] || 1).first.to_i
    [page_number, 1].max
  end

  def query_sort_by
    sort_by = (Array(@options[:sort_by]).first || :none).to_sym
    SORT_OPTIONS.keys.include?(sort_by) ? sort_by : DEFAULT_SORT[0]
  end

  def query_sort_dir
    sort_dir = (Array(@options[:sort_dir]).first || :none).to_sym
    SORT_OPTIONS[query_sort_by].keys.include?(sort_dir) ? sort_dir : DEFAULT_SORT[1]
  end

  def vip_values
    vip_options = ( @options[:vip] || [] ).map(&:to_sym)
    vip = vip_options.include?(:vip)
    notvip = vip_options.include?(:notvip)
    [
      {label: 'Yes', value: (vip ? 'vip' : false)},
      {label: 'No', value: (notvip ? 'notvip' : false)}
    ]
  end

  def property_values
    property_ids = @options[:property_ids]
    properties = Property.active.where(id: property_ids).order(name: :asc)
    return properties.map{|p| {label: p.name, value: p.id}}
  end

  def property_options
    begin
      if @user
        begin
          property_ids = LeadPolicy::Scope.new(@user, @skope).resolve.
                          select("distinct property_id").
                          map(&:property_id)
          properties = Property.active.where(id: property_ids)
        rescue
          # HACK HACK HACK
          # Sometimes there is an SQL error when the user is a corporate role...WHY???
          properties = Property.active
        end
      else
        properties = Property.active
      end
    end
    return properties.order(name: :asc).map{|p| {label: p.name, value: p.id}}
  end

  def agent_options
    if @user
      property_ids = PropertyPolicy::Scope.new(@user, Property).resolve.pluck(:id)
      agents = User.includes([:assignments, :profile]).
        where(property_users: {property_id: property_ids})
    else
      agents = PropertyUser.select("distinct user_id").map(&:user)
    end
    return agents.
      map{ |u| {label: u.name, value: u.id} }.
      sort_by{|x| ( x[:label] || '' ).split.last}
  end

  def bedroom_options
    (1..4).to_a.map{|v| { label: v.to_s, value: v.to_s }}
  end

end
