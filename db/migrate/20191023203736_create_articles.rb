class CreateArticles < ActiveRecord::Migration[6.0]
  def change
    create_table :articles, id: :uuid do |t|
      t.string :articletype
      t.string :category
      t.boolean :published, default: false
      t.string :title
      t.text :body
      t.string :slug
      t.uuid :user_id
      t.string :contextid, default: 'hidden'
      t.string :audience, default: 'all'
      t.timestamps
    end
  end
end
