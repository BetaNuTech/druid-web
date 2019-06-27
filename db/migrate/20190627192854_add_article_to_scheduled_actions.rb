class AddArticleToScheduledActions < ActiveRecord::Migration[5.2]
  def self.up
    add_column :scheduled_actions, :article_id, :uuid
    add_column :scheduled_actions, :article_type, :string
    add_index :scheduled_actions, [:article_type, :article_id], name: :scheduled_actions_article_idx
  end

  def self.down
    remove_index :scheduled_actions, name: :scheduled_actions_article_idx
    remove_column :scheduled_actions, :article_id
    remove_column :scheduled_actions, :article_type
  end
end
