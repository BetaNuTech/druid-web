# == Schema Information
#
# Table name: articles
#
#  id          :uuid             not null, primary key
#  articletype :string
#  category    :string
#  published   :boolean          default(FALSE)
#  title       :string
#  body        :text
#  slug        :string
#  user_id     :uuid
#  contextid   :string           default("hidden")
#  audience    :string           default("all")
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Article < ApplicationRecord
  class ArticleValidator < ActiveModel::Validator
    def validate(record)
      validate_articletype_for_user_role(record)
      validate_audience_for_user_role(record)
    end

    def validate_articletype_for_user_role(record)
      if record.user.present?
        unless record.permitted_articletypes.include?(record.articletype)
          record.errors[:base] << 'You are not allowed to create this type of article'
        end
      else
        unless Article.articletypes.include?(record.articletype)
          record.errors[:articletype] << 'Invalid article type'
        end
      end
    end

    def validate_audience_for_user_role(record)
      if record.user.present?
        unless record.permitted_audiences.include?(record.audience)
          record.errors[:base] << 'You are not allowed to create an article with this audience'
        end
      else
        unless Article.audiences.include?(record.audience)
          record.errors[:audience] << 'Invalid audience'
        end
      end
    end
  end

  ### Class Concerns/Extensions
  audited
  include Seeds::Seedable

  ### Constants
  ALLOWED_PARAMS = %w{articletype category published title body contextid audience}
  AUDIENCES = %w{all administrator corporate manager property private}
  ARTICLETYPES = %w{news blog help tooltip}

  ### Attributes

  ### Enums

  ### Associations
  belongs_to :user, optional: true

  ### Scopes
  scope :for_audiences, -> (audiences) { where(audience: audiences) }
  scope :published, -> { where(published: true) }
  scope :drafts, -> { where(published: false) }
  scope :help, -> { where(articletype: 'help') }
  scope :news, -> { where(articletype: 'news') }
  scope :blog, -> { where(articletype: 'blog') }
  scope :tooltip, -> { where(articletype: 'tooltip') }
  scope :tooltip_for, -> (slug) { where(articletype: 'tooltip', slug: slug, published: true) }

  ### Validations
  validates :slug, presence: true
  validates :title, presence: true
  validates :body, presence: true
  validates :audience, presence: true
  validates_with ArticleValidator

  ### Callbacks
  before_validation :set_slug, on: :create

  ### Class Methods
  class << self
    def audiences
      AUDIENCES
    end

    def articletypes
      ARTICLETYPES
    end
  end

  ### Instance Methods

  def context
    AppContext.humanize_context(contextid)
  end

  def related(include_tooltips: false)
    skope = Article.where("contextid ilike '#{contextid.split('#').first}%'").
                    where("id != ?", self.id)
    unless include_tooltips
      skope = skope.where("articletype != 'tooltip'")
    end
    return skope
  end

  def permitted_articletypes
    return Article.articletypes unless user.present?

    return case user&.role&.slug
      when 'administrator'
        Article.articletypes
      when 'corporate'
        Article.articletypes
      when 'manager'
        %w{help}
      when 'property'
        %w{help}
      else
        []
      end
  end

  def permitted_audiences
    return Article.audiences unless user.present?
    return case user&.role&.slug
      when 'administrator'
        Article.audiences
      when 'corporate'
        Article.audiences
      when 'manager'
        %w{all manager property private}
      when 'property'
        %w{all property private}
      else
        ['private']
      end
  end

  def to_seed_yml
    data = slice(:slug, :title, :contextid, :articletype, :category, :audience, :published, :body).
            to_h.
            symbolize_keys
    data[:body] = (data[:body] || '').
										gsub("\r\n",'').
										gsub("\t",'')
    return [data].to_yaml(options: {line_width: -1})
  end

  private

  def set_slug
    self.slug = self.title&.parameterize unless self.slug.present?
  end

end
