class RenameAgentRoleToProperty < ActiveRecord::Migration[5.2]
  def self.up
    Role.where(slug: 'agent').update_all(slug: 'property')
  end
  def self.down
    Role.where(slug: 'property').update_all(slug: 'agent')
  end
end
