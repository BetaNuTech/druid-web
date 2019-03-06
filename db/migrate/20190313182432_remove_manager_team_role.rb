class RemoveManagerTeamRole < ActiveRecord::Migration[5.2]
  def self.up
    Teamrole.where(slug: 'manager').destroy_all
  end

  def self.down
    Teamrole.create(slug: 'manager', name: 'Manager', description: 'Property Manager')
  end
end
