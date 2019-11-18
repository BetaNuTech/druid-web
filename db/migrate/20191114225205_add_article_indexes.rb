class AddArticleIndexes < ActiveRecord::Migration[6.0]
  def change
    add_index :articles, [:user_id, :published, :audience, :articletype, :contextid, :created_at], name: 'article_info_idx'
    add_index :articles, :articletype
    add_index :articles, :contextid
    add_index :articles, :title
    add_index :articles, :created_at
  end
end
