class RenameRoleOperatorToCorporate < ActiveRecord::Migration[5.2]
  def self.up
    Role.where(slug: 'operator').update_all(slug: 'corporate', name: 'Corporate')
  end

  def self.down
    Role.where(slug: 'corporate').update_all(slug: 'operator', name: 'Operator')
  end
end
