RSpec.shared_context "scheduled_actions" do
  include_context "team_members"
  include_context "engagement_policy"

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:scheduled_action1) { create(:scheduled_action, user: user) }
  let(:scheduled_action2) {
    sa = create(:scheduled_action, user: user)
    schedule1 = scheduled_action1.schedule
    sa.schedule = schedule1.dup
    sa.schedule.date = schedule1.date + 10.days
    sa.save
    sa
  }
  let(:other_user_action) {
    sa = create(:scheduled_action, user: other_user)
    schedule1 = scheduled_action1.schedule
    sa.schedule = schedule1.dup
    sa.schedule.time = schedule1.time + 10.minutes
    sa.save
    sa
  }
  let(:conflicting_action) {
    sa = create(:scheduled_action, user: scheduled_action1.user)
    schedule1 = scheduled_action1.schedule
    sa.schedule = schedule1.dup
    sa.schedule.time = schedule1.time + 10.minutes
    sa.save
    sa
  }

  before do
    scheduled_action1
    scheduled_action2
    other_user_action
  end
end
