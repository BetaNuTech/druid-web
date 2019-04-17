class SetOutgoingMessageReadAt < ActiveRecord::Migration[5.2]
  def change
    Message.all.each do |m|
      if m.outgoing?
        if m.read_at.nil?
          m.read_at = m.delivered_at
          m.read_by_user_id = m.user_id
          m.save
        end
      end
    end
  end
end
