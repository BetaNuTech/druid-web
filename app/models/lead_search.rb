class LeadSearch
  ALLOWED_PARAMS = [ :user_ids, :property_ids, :priorities, :states, :last_name, :first_name, :id_number, :page, :per_page, :sort_by, :sort_dir ]
  LEAD_TABLE = Lead.table_name
  DEFAULT_SORT = [:recent, :asc]
  DEFAULT_PER_PAGE = 20
  SORT_OPTIONS = {
    priority: {
      asc: "#{LEAD_TABLE}.priority ASC",
      desc: "#{LEAD_TABLE}.priority DESC" },
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
    @options = options || {}
    @skope = @default_skope
    @filter_applied = false
  end

  def collection
    query_skope.skope
  end

  def query_skope
    self.
      filter_by_state.
      filter_by_priority.
      filter_by_user.
      filter_by_property.
      filter_by_first_name.
      filter_by_last_name.
      filter_by_id_number.
      finalize.
      sort
  end

  def paginated
    self.query_skope.paginate
  end

  def record_count
    self.collection.count
  end

  def total_pages
    (record_count / query_limit).ceil
  end

  def next_page_options
    opts = @options
    next_page = (opts[:page] || 0) + 1
    opts[:page] = [next_page, total_pages].min
    return opts
  end

  def previous_page_options
    opts = @options
    previous_page = [1, ( (opts[:page] || 0) - 1 ) ].max
    opts[:page] = previous_page
    return opts
  end

  def first_page_options
    opts = @options
    opts[:page] = 1
    return opts
  end

  def last_page_options
    opts = @options
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
    if first_name.present?
      @skope = @skope.
        where("#{LEAD_TABLE}.first_name ILIKE ?", "%#{first_name}%")
      @filter_applied = true
    end
    return self
  end

  def filter_by_last_name(last_name=nil)
    last_name ||= @options[:last_name]
    if last_name.present?
      @skope = @skope.
        where("#{LEAD_TABLE}.last_name ILIKE ?", "%#{last_name}%")
      @filter_applied = true
    end
    return self
  end

  def filter_by_id_number(id_number=nil)
    id_number ||= @options[:id_number]
    if id_number.present?
      @skope = @skope.
        where(id_number: id_number)
      @filter_applied = true
    end
    return self
  end

  def paginate
    @skope = @skope.limit(query_limit).offset(query_offset)
  end

  def sort
    @skope = @skope.order(query_sort)
    return self
  end

  def finalize
    if @filter_applied
      ids = ids_from(@skope)
      @skope = @skope.where(id: ids)
    end
    return self
  end

  private

  def query_sort
    SORT_OPTIONS.fetch(query_sort_by).fetch(query_sort_dir)
  end

  def query_limit
    ( @options[:per_page] || DEFAULT_PER_PAGE ).to_i
  end

  def query_offset
    query_page * query_limit - query_limit
  end

  def query_page
    ( @options[:page] || 1 ).to_i
  end

  def query_sort_by
    sort_by = (@options[:sort_by] || :none).to_sym
    SORT_OPTIONS.keys.include?(sort_by) ? sort_by : DEFAULT_SORT[0]
  end

  def query_sort_dir
    sort_dir = (@options[:sort_dir] || :none).to_sym
    SORT_OPTIONS[query_sort_by].keys.include?(sort_dir) ? sort_dir : DEFAULT_SORT[1]
  end

  def ids_from(skope)
    skope.select("#{LEAD_TABLE}.id").map(&:id)
  end
end
