class RemoveConstraints < ActiveRecord::Migration[6.1]
  def up
    execute 'ALTER TABLE engagement_policy_action_compliances DROP CONSTRAINT engagement_policy_action_compliances_scheduled_action_id_fk'
  end
  def down
    #noop
  end
end
