# == Schema Information
#
# Table name: teamroles
#
#  id          :uuid             not null, primary key
#  name        :string
#  slug        :string
#  description :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Teamrole < ApplicationRecord
  ### Class Concerns/Extensions
  include Comparable
  audited

  ### Constants
  ALLOWED_PARAMS = [:id, :name, :slug, :description]
  HIERARCHY = [ :lead, :agent, :none]

  ### Validations
  validates :name, :slug,
    presence: true, uniqueness: true

  ### Associations
  has_many :users

  ### Class Methods

  def self.agent
    self.where(slug: 'agent').first
  end

  def self.manager
    raise "Manager Teamrole is deprecated"
    #self.where(slug: 'manager').first
  end

  def self.lead
    self.where(slug: 'lead').first
  end

  def self.none
    self.where(slug: 'none').first
  end

  ### Instance Methods

  def <=>(other)
    return 1 if other.nil?
    return 1 if HIERARCHY.index(other.slug&.to_sym).nil?
    return -1 if HIERARCHY.index(slug.to_sym).nil?
    return HIERARCHY.index(other.slug.to_sym) <=> HIERARCHY.index(slug.to_sym)
  end

  def agent?
    slug == 'agent'
  end

  def manager?
    raise "Manager Teamrole is deprecated"
    #slug == 'manager'
  end

  def lead?
    slug == 'lead'
  end

  def none?
    slug == 'none'
  end

end
