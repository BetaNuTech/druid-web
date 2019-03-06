# == Schema Information
#
# Table name: roles
#
#  id          :uuid             not null, primary key
#  name        :string
#  slug        :string
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Role < ApplicationRecord
  ### Class Concerns/Extensions

  include Comparable
  audited

  ### Constants

  ALLOWED_PARAMS = [:id, :name, :slug, :description]
  HIERARCHY = [ :administrator, :corporate, :manager, :property ]


  ### Validations

  validates :name, :slug,
    presence: true, uniqueness: true


  ### Class Methods

  def self.administrator
    self.where(slug: 'administrator').first
  end

  def self.agent
    raise "Agent User Role is deprecated"
    #self.where(slug: 'agent').first
  end

  def self.property
    self.where(slug: 'property').first
  end

  def self.corporate
    self.where(slug: 'corporate').first
  end

  def self.manager
    self.where(slug: 'manager').first
  end

  ### Instance Methods

  def <=>(other)
    return 1 if other.nil?
    return 1 if HIERARCHY.index(other.slug&.to_sym).nil?
    return -1 if HIERARCHY.index(slug.to_sym).nil?
    return HIERARCHY.index(other.slug.to_sym) <=> HIERARCHY.index(slug.to_sym)
  end

  def administrator?
    slug == 'administrator'
  end

  def corporate?
    slug == 'corporate'
  end

  def manager?
    slug == 'manager'
  end

  def agent?
    raise "Agent User Role is deprecated"
    slug == 'agent'
  end

  def property?
    slug == 'property'
  end

  def admin?
    administrator? || corporate?
  end

  def user?
    manager? || property?
  end

end
