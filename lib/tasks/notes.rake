namespace :notes do

  desc 'correct ownership'
  task :correct_ownership => :environment do

    puts "*** Correcting ownership of Lead Notes"

		agent_sql=<<~EOF
			SELECT notes.id AS noteid, leads.user_id AS userid
			FROM notes
			INNER JOIN leads
			ON
				leads.state != 'open'
				AND notes.notable_type = 'Lead'
				AND notes.notable_id = leads.id
			WHERE
				notes.user_id IS NULL
				AND notes.reason_id IS NULL
				AND notes.lead_action_id IS NULL
				AND notes.content IS NOT NULL
		EOF

		assign_user_id_sql=<<~EOF
			WITH n2 AS (#{agent_sql})
			UPDATE notes
			SET user_id = n2.userid
			FROM n2
			WHERE id = n2.noteid
		EOF

		system_sql=<<~EOF
			SELECT notes.id
			FROM notes
			WHERE
				notes.user_id IS NOT NULL
				AND notes.content IS NOT NULL
				AND ( notes.reason_id IS NOT NULL OR notes.lead_action_id IS NOT NULL )
				AND notes.notable_type = 'Lead'
		EOF

		#agent_note_ids = Note.connection.execute(agent_sql).map{|r| r["noteid"]}
		system_note_ids = Note.connection.execute(system_sql).map{|r| r["id"]}

		Note.transaction do
			print " * Assigning user_id to agent notes..."
			Note.connection.execute(assign_user_id_sql)
			puts "Done"

			print " * Removing user_id from system notes..."
			system_note_ids.in_groups_of(10000, false) do |id_group|
				Note.where(id: id_group).update_all(user_id: nil)
				print "."
			end
			puts "Done"
			true
		end

  end

end
