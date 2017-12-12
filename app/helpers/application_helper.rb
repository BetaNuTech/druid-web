module ApplicationHelper
  def short_date(datetime)
    datetime.present? ? datetime.strftime('%m-%d') : nil
  end

  def glyph(type)
    glyph_mappings = {
      create: ['Create', 'glyphicon glyphicon-plus'],
      edit: ['Edit', 'glyphicon glyphicon-pencil'],
      show: ['Show', 'glyphicon glyphicon-eye-open'],
      delete: ['Delete', 'glyphicon glyphicon-trash'],
      back: ['Back', 'glyphicon glyphicon-arrow-left'],
      email: ['Email',  'glyphicon glyphicon-envelope'],
      phone: ['Phone',  'glyphicon glyphicon-earphone' ],
      fax: ['Fax',  'glyphicon glyphicon-file' ],
      person: ['Person',  'glyphicon glyphicon-user' ],
      address: ['Address',  'glyphicon glyphicon-home' ],
    }
    text, glyph_class = glyph_mappings.fetch(type.to_sym)
    content_tag(:span, ' ', {class: glyph_class, "aria-hidden": true})
  end

  def nav_active_class(path)
    request.path.match(path) ? 'btn-success btn-nav-active' : 'btn-info'
  end

  def nav_active_dropdown_class(path)
    request.path.match(path) ? 'btn-success' : 'btn-info'
  end
end
