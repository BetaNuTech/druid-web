class FixMarketingSourceEmails < ActiveRecord::Migration[6.1]
  def change
    MarketingSource.where("tracking_email ilike '1b524cb3122f466ecc5a%'").each do |ms|
      ms.tracking_email = ms.tracking_email.sub('1b524cb3122f466ecc5a','47064e037e5740bbedad')
      ms.save
    end
  end
end
