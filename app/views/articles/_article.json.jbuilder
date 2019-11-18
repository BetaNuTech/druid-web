json.extract! article, :id, :articletype, :category, :published, :title, :body, :slug, :user_id, :contextid, :audience, :created_at, :updated_at
json.url article_url(article, format: :json)
