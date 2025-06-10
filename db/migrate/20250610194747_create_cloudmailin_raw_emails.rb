class CreateCloudmailinRawEmails < ActiveRecord::Migration[6.1]
  def change
    create_table :cloudmailin_raw_emails, id: :uuid do |t|
      t.jsonb :raw_data, null: false
      t.string :property_code
      t.uuid :property_id
      t.string :status, default: 'pending' # pending, processing, completed, failed
      t.string :parser_used
      t.uuid :lead_id
      t.text :error_message
      t.integer :retry_count, default: 0
      t.datetime :processed_at
      t.jsonb :openai_response
      t.float :openai_confidence_score
      
      t.timestamps
    end

    add_index :cloudmailin_raw_emails, :status
    add_index :cloudmailin_raw_emails, :property_id
    add_index :cloudmailin_raw_emails, :lead_id
    add_index :cloudmailin_raw_emails, :created_at
  end
end
