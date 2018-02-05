class LeadSearch
  ALLOWED_PARAMS = [ :user_ids, :property_ids, :priorities, :states, :last_name, :first_name, :id_number, :text, :page, :per_page, :sort_by, :sort_dir ]
  LEAD_TABLE = Lead.table_name
  DEFAULT_SORT = [:priority, :desc]
  DEFAULT_PER_PAGE = 10
  SORT_OPTIONS = {
    priority: {
      asc: "#{LEAD_TABLE}.priority ASC, #{LEAD_TABLE}.created_at ASC",
      desc: "#{LEAD_TABLE}.priority DESC, #{LEAD_TABLE}.created_at DESC" },
    recent: {
      asc: "#{LEAD_TABLE}.created_at ASC",
      desc: "#{LEAD_TABLE}.created_at DESC" },
    lead_name: {
      asc: "#{LEAD_TABLE}.last_name ASC, #{LEAD_TABLE}.first_name ASC",
      desc: "#{LEAD_TABLE}.last_name DESC, #{LEAD_TABLE}.first_name DESC" }
  }

  attr_reader :options, :skope

  def initialize(options={}, skope=Lead)
    @default_skope = skope
    @options = (options || {})
    @options = @options.to_unsafe_h unless @options.is_a?(Hash)
    @skope = @default_skope
    @filter_applied = false
    @perform_sort = true
  end

  def collection
    query_skope.skope
  end

  def query_skope
    filtered_skope = self.
      filter_by_state.
      filter_by_priority.
      filter_by_user.
      filter_by_property.
      filter_by_first_name.
      filter_by_last_name.
      filter_by_id_number.
      finalize.
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
        "_index" => ["Agents", "Properties", "Priorities", "States", "First Name", "Last Name", "ID Number", "Search"],
        "Agents" => {
          param: "user_ids",
          values: User.where(id: @options[:user_ids]).map{|u| {label: u.name, value: u.id}}
        },
        "Properties" => {
          param: "property_ids",
          values: Property.where(id: @options[:property_ids]).map{|p| {label: p.name, value: p.id}}
        },
        "Priorities" => {
          param: "priorities",
          values: Array(@options[:priorities]).map{|p| {label: p.capitalize, value: p}}
        },
        "States" => {
          param: "states",
          values: Array(@options[:states]).map{|s| {label: s.capitalize, value: s}}
        },
        "First Name" => {
          param: "first_name",
          values: Array(@options[:first_name]).map{|v| {label: v, value: v} }
        },
        "Last Name" => {
          param: "last_name",
          values: Array(@options[:last_name]).map{|v| {label: v, value: v} }
        },
        "ID Number" => {
          param: "id_number",
          values: Array(@options[:id_number]).map{|v| {label: v, value: v} }
        },
        "Search" => {
          param: "text",
          values: Array(@options[:text]).map{|v| {label: v, value: v} }
        }
      },
      "Pagination" => {
        "_index" => ["Page", "Per Page", "Sort By", "Sort Dir"],
        "_total_pages" => total_pages,
        "Page" => {
          param: "page",
          values: [ {label: "Page", value: query_page} ]
        },
        "Per Page" => {
          param: "per_page",
          values: [{ label: "Per Page", value: query_limit }]
        },
        "Sort By" => {
          param: "sort_by",
          values: [ { label: "Sort By", value: query_sort_by }]
        },
        "Sort Dir" => {
          param: "sort_dir",
          values: [ { label: "Sort Direction", value: query_sort_dir }]
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
        includes(:property).
        where(properties: {id: property_ids})
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

  def paginate
    @skope.limit(query_limit).offset(query_offset)
  end

  def sort
    @skope = @skope.order(query_sort)
    return self
  end

  def finalize
    if @filter_applied
      ids = ids_from(@skope)
      @skope = @default_skope.where(id: ids)
    end
    return self
  end

  private

  def query_sort
    SORT_OPTIONS.fetch(query_sort_by).fetch(query_sort_dir)
  end

  def query_limit
    per_page = Array(@options[:per_page] || nil).first || DEFAULT_PER_PAGE
    per_page.to_i
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

  def ids_from(skope)
    skope.select("#{LEAD_TABLE}.id").map(&:id)
  end
end
