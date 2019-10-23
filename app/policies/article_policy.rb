class ArticlePolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      skope = scope
      return case user
        when ->(u) { u.admin? }
          skope
        else
          skope.where(user_id: user.id).
            or(skope.published.for_audiences(['all', user.role.slug]))
        end
    end
  end

  def index?
    user.admin? || user.user?
  end

  def show?
    (record.published && index?) || edit?
  end

  def new?
    index?
  end

  def create?
    index?
  end

  def edit?
    return case user
      when -> (u) { u.admin? }
        true
      when -> (u) { u.manager? }
        true
      else
        is_owner?
      end
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end

  def allowed_params
    reject_params = []
    case user
      when ->(u) { u.admin? }
        # NOOP: Full permissions
      when ->(u) { u.user? }
        reject_params << :user_id
      end
    valid_article_params = Article::ALLOWED_PARAMS - reject_params
    return valid_article_params
  end

  def articletype_visible?(articletype)
    return case articletype
        when 'help'
          true
        when 'tooltip'
          user.admin?
        when 'news'
          true
        when 'blog'
          true
        end
  end

  def manage_tooltips?
    user.admin?
  end

  def manage_news?
    user.admin?
  end

  def manage_blog?
    user.admin?
  end

  def manage_help?
    user.admin? || user.manager?
  end

end
