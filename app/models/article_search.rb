class ArticleSearch
  attr_reader :params, :id, :articletype, :contextid, :skope, :order

  def initialize(params:, skope: Article)
    @filtered = false
    @skope = skope
    @order = "created_at DESC"
    @raw_params = HashWithIndifferentAccess.new params
    set_params
  end

  def filtered?
    @filtered
  end

  def search
    if @id.present?
      if @related.present?
        find_related
      else
        find_by_id.results
      end
    else
      find_by_articletype.
        find_by_contextid.
        ordered.
        results
    end
  end

  def find_related
    find_by_id.results.first&.related
  end

  def find_by_id
    @skope = @skope.where(id: @id)
    return self
  end

  def find_by_articletype
    if @articletype.present?
      @skope = @skope.where(articletype: @articletype)
    end
    return self
  end

  def find_by_contextid
    if @contextid.present?
      controller, action = @contextid.split('#')
      if action.nil?
        @skope = @skope.where("articles.contextid ilike ?", controller + '%')
      else
        @skope = @skope.where(contextid: @contextid)
      end
    end
    return self
  end

  def ordered
    @skope = @skope.order(@order)
    return self
  end

  def results
    return select_without_body(@skope)
  end

  private

  def select_without_body(skope)
    columns = Article.attribute_names - ['body']
    return skope.select(columns)
  end

  def set_params
    @params = HashWithIndifferentAccess.new
    if (@articletype = @raw_params[:articletype]).present?
      @params[:articletype] = @articletype
    end
    if (@contextid = @raw_params[:contextid]).present?
      @params[:contextid] = @contextid
      @filtered = true
    end
    if (@id = @raw_params[:id]).present?
      @params[:id] = @id
      @filtered = true
    end
    if (@related = ( ( @raw_params[:related] || 'false').to_s.downcase == 'true' ))
      @params[:related] = @related
      @filtered = true
    end
  end

end
