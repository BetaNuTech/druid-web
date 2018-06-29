class AddCallLogToLead < ActiveRecord::Migration[5.2]
  def change
    add_column :leads, :call_log, :json
    add_column :leads, :call_log_updated_at, :datetime
  end
end
