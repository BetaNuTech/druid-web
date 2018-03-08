module ApplicationHelper
  def short_date(datetime)
    datetime.present? ? datetime.strftime('%m-%d') : nil
  end

  def glyph(type)
    _text, glyph_class = GLYPHS.fetch(type.to_s,'')
    content_tag(:span, ' ', {class: glyph_class, "aria-hidden": true})
  end

  def select_glyph(val)
    options_for_select(GLYPHS.keys.map{|g| [g,g]}, val)
  end

  def nav_active_class(path)
    request.path.match(path) ? 'btn-success btn-nav-active' : 'btn-info'
  end

  def nav_active_dropdown_class(path)
    request.path.match(path) ? 'btn-success' : 'btn-info'
  end

  def select_state(val)
    options_for_select(us_states, val)
  end
end
