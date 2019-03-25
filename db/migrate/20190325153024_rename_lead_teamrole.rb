class RenameLeadTeamrole < ActiveRecord::Migration[5.2]
  def self.up
    if (teamrole = Teamrole.where(slug: 'lead').first)
      teamrole.name = 'Talent Resource Manager'
      teamrole.save
    end
  end
  def self.down
    if (teamrole = Teamrole.where(slug: 'lead').first)
      teamrole.name = 'Lead'
      teamrole.save
    end
  end
end
