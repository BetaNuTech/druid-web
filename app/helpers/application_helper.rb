module ApplicationHelper
  def short_date(datetime)
    datetime.present? ? datetime.strftime('%m-%d') : nil
  end

  def short_time(datetime)
    datetime.present? ? datetime.strftime('%l:%M%p') : nil
  end

  def short_datetime(datetime)
    datetime.present? ? datetime.strftime('%m-%d %l:%M%p') : nil
  end

  def long_datetime(datetime)
    datetime.present? ? datetime.strftime('%B %e, %Y at %l:%M%p') : nil
  end

  def long_date(datetime)
    datetime.present? ? datetime.strftime('%B %e, %Y') : nil
  end

  def glyph(type)
    _text, glyph_class = GLYPHS.fetch(type.to_s.gsub('_','-'),'')
    content_tag(:span, ' ', {class: glyph_class, "aria-hidden": true})
  end

  def select_glyph(val)
    options_for_select(GLYPHS.keys.map{|g| [g,g]}, val)
  end

  def nav_active_class(path)
    request.path.match(path) ? 'btn-success btn-nav-active' : 'btn-primary'
  end

  def nav_active_dropdown_class(path)
    request.path.match(path) ? 'btn-success' : 'btn-primary'
  end

  def select_state(val)
    options_for_select(us_states, val)
  end

  def navbar_cache_key
    [current_user, current_user.try(:messages).try(:unread).try(:size)]
  end

  def action_and_reason(record)
    return "" unless record.present?
    content_tag(:small) do
      content_tag(:span) do
        concat content_tag(:span, record&.lead_action&.name)
        if record.respond_to?(:article_selectable?)
          if record.article.present?
            concat ": "
            concat(content_tag(:span) do
              link_to(record.article.name, url_for(record.article))
            end)
          else
            if record.article_selectable? && policy(record).edit?
              concat '&nbsp;'.html_safe
              concat link_to("Select", url_for(action: :edit, controller: record.class.name.pluralize.underscore, id: record.id), class: "btn btn-xs btn-primary")
            end
          end
        end
        if record&.reason&.present?
          if record&.lead_action&.present?
            concat content_tag(:span, ' &rarr; '.html_safe)
          end
          concat content_tag(:span, record&.reason&.name)
        end
      end
    end
  end

  def current_page_help_path
    contextid = AppContext.for_params(params).first
    if contextid.present?
      articles_path(articletype: 'help', contextid: contextid)
    else
      articles_path(articletype: 'help')
    end
  end

  def tooltip(title:, glyph: :info_sign, placement: :top)
    article = Article.published.tooltip.where(title: title).first
    if article&.body&.present?
      content_tag(:span, {data: {toggle: 'tooltip', placement: placement}, title: strip_tags(article.body).chomp}) do
        glyph(:info_sign)
      end
    else
      raw("<!-- Tooltip '#{title}' missing -->")
    end
  end

  def tooltip_block(slug, show = true, &block)
    unless show
      return yield
    end

    article = Article.tooltip_for(slug).first
    if article&.body&.present?
      content_tag(:span, {data: {toggle: 'tooltip', placement: 'top'}, title: strip_tags(article.body).chomp}) do
        yield
      end
    else
      raw("<!-- Tooltip '#{slug}' missing -->") +
      yield
    end
  end

end
