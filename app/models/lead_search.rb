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

  attr_reader :options

  def initialize(options={}, skope=Lead)
    @default_skope = skope
    @options = options
  end

  def collection
    filter_applied = false
    skope = @default_skope

    # Filter by State
    if @options[:states].present?
      skope = skope.
        where(state: @options[:states])
      filter_applied = true
    end

    # Filter by Priority
    if @options[:priorities].present?
      priority_list = @options[:priorities].compact.map(&:to_sym)
      skope = skope.
        where(priority: priority_list)
      filter_applied = true
    end

    # Filter by User/Agent
    if @options[:user_ids].present?
      skope = skope.
        includes(:user).
        where(users: {id: @options[:user_ids]})
      filter_applied = true
    end

    # Filter by Property
    if @options[:property_ids].present?
      skope = skope.
        includes(:property).
        where(properties: {id: @options[:property_ids]})
      filter_applied = true
    end

    # Filter by First Name
    if @options[:first_name].present?
      skope = skope.
        where("#{LEAD_TABLE}.first_name ILIKE ?", "%#{@options[:first_name]}%")
      filter_applied = true
    end

    # Filter by Last Name
    if @options[:last_name].present?
      skope = skope.
        where("#{LEAD_TABLE}.last_name ILIKE ?", "%#{@options[:last_name]}%")
      filter_applied = true
    end

    # Filter by ID number
    if @options[:id_number].present?
      skope = skope.
        where(id_number: @options[:id_number])
      filter_applied = true
    end

    # Paginate
    skope = skope.limit(query_limit).offset(query_offset)

    if filter_applied
      ids = ids_from(skope)
      skope = skope.where(id: ids)
    else
      skope = @default_skope
    end

    return skope.order(query_sort)
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

  def query_sort
    SORT_OPTIONS.fetch(query_sort_by).fetch(query_sort_dir)
  end

  def ids_from(skope)
    skope.select("#{LEAD_TABLE}.id").map(&:id)
  end
end
