class SetSelectTaskReasonDefault < ActiveRecord::Migration[6.0]
  def change
    User.active.each do |user|
      user.switch_setting!(:select_task_reason, false)
    end
  end
end
