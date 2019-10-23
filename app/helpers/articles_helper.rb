module ArticlesHelper
  def select_articletype(article)
    articletypes = article.permitted_articletypes.
      map{|a| [a.capitalize,a]}
    options_for_select(articletypes, article.articletype)
  end

  def select_article_category(val)
    categories = %w{general}.map{|c| [c.capitalize, c]}
    options_for_select(categories, val)
  end

  def select_article_audience(article)
    audiences = article.permitted_audiences.
      map{|a| [a.capitalize,a]}
    options_for_select(audiences, article.audience)
  end

  def select_article_contextid(val)
    contexts = AppContext.options_for_accessible_to(current_user)
    options_for_select(contexts, val)
  end

  def decorated_article_link(article)
    link_to article_path(article) do 
      content_tag(:span, class: 'btn btn-xs btn-primary') do
        article.articletype.humanize
      end +
      content_tag(:span, raw( "&nbsp;" )) +
      content_tag(:span) do
        article.title
      end
    end
    
  end

end
