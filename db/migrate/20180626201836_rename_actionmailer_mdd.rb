class RenameActionmailerMdd < ActiveRecord::Migration[5.2]
  def self.up
    MessageDeliveryAdapter.where(slug: 'ActionMailer').update_all(slug: 'Actionmailer')
  end

  def self.down
    MessageDeliveryAdapter.where(slug: 'Actionmailer').update_all(slug: 'ActionMailer')
  end
end
