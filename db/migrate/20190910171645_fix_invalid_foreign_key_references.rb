class FixInvalidForeignKeyReferences < ActiveRecord::Migration[5.2]
  def change
    # Remove TeamUser records that reference nonexistent Teamroles
    sql = "SELECT tu.id, tu.user_id, tu.teamrole_id FROM team_users tu WHERE NOT EXISTS ( SELECT 1 FROM teamroles WHERE tu.teamrole_id = teamroles.id)"
    result = ActiveRecord::Base.connection.exec_query(sql).entries
    TeamUser.where(id: result.map{|r| r["id"]}).delete_all
  end
end
