class RenameLeadActionTourUnits < ActiveRecord::Migration[5.2]
  def self.up
    if (la = LeadAction.where(name: 'Tour Units').first)
      la.name = 'Show Unit'
      la.description = 'Show Unit(s) to Lead'
      la.save!
    end
  end

  def self.down
    if (la = LeadAction.where(name: 'Show Unit').first)
      la.name = 'Tour Units'
      la.description = 'Tour units with Lead'
      la.save!
    end
  end
end
