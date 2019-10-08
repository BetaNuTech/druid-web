class RejectDisqualifiedLeadTasks < ActiveRecord::Migration[6.0]
  def change
    sql=<<~EOL
      UPDATE scheduled_actions
        SET state = 'rejected'
      FROM leads
      WHERE
        scheduled_actions.state = 'pending'
        AND leads.id = scheduled_actions.target_id
        AND scheduled_actions.target_type = 'Lead';
EOL

    ActiveRecord::Base.connection.execute(sql)
  end
end
