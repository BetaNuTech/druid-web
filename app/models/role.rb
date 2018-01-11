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
  include Comparable

  ALLOWED_PARAMS = [:id, :name, :slug, :description]

  validates :name, :slug,
    presence: true, uniqueness: true

  HIERARCHY = [
    :administrator,
    :operator,
    :agent
  ]

  # Class Methods
  #

  def self.administrator
    self.where(slug: 'administrator').first
  end

  def self.agent
    self.where(slug: 'agent').first
  end

  def self.operator
    self.where(slug: 'operator').first
  end

  # Instance Methods
  #

  def <=>(other)
    return 1 if other.nil?
    return 1 if HIERARCHY.index(other.slug&.to_sym).nil?
    return -1 if HIERARCHY.index(slug.to_sym).nil?
    return HIERARCHY.index(other.slug.to_sym) <=> HIERARCHY.index(slug.to_sym)
  end

  def administrator?
    slug == 'administrator'
  end

  def operator?
    slug == 'operator'
  end

  def agent?
    slug == 'agent'
  end

  def admin?
    administrator? || operator?
  end

  def user?
    agent?
  end

end
