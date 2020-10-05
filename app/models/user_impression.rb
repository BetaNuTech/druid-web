# == Schema Information
#
# Table name: user_impressions
#
#  id         :uuid             not null, primary key
#  user_id    :uuid
#  reference  :string
#  path       :string
#  referrer   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class UserImpression < ApplicationRecord
  belongs_to :user
  validates :reference, presence: true

  def self.by_user_report
    sql = <<~SQL
      -- User Impression Stats - top 5 pages by User

      WITH impression_stats AS (
        SELECT
          impressions.user_id,
          impressions.reference,
          impressions.count,
          RANK () OVER (
            PARTITION BY
              impressions.user_id
            ORDER BY impressions.count DESC
          ) user_page_rank
        FROM
          (
            SELECT
              user_id,
              reference,
              COUNT(id) AS count
            FROM
              user_impressions
            GROUP BY
              user_id,
              reference
            ORDER BY
              user_id ASC,
              count DESC
          ) AS impressions
      )
      SELECT
        users.email AS email,
        roles.name AS user_role,
      --	impression_stats.user_id AS user_id,
        impression_stats.reference AS reference,
        impression_stats.count AS count,
        impression_stats.user_page_rank AS user_page_rank
      FROM
        impression_stats
      INNER JOIN users
        ON users.id = impression_stats.user_id
      INNER JOIN roles
        ON users.role_id = roles.id
      WHERE
        user_page_rank <= 5;
    SQL

    ActiveRecord::Base.connection.execute(sql).to_a
  end

  def self.by_user_report_csv
    data = by_user_report
    CSV.generate do |csv|
      csv << data.first.keys
      data.each do |row|
        csv << row.values
      end
    end
  end

end
