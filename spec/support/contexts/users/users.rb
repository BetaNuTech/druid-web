RSpec.shared_context "users" do
  let(:unroled_user) {
    user = create(:user)
    user.save
    user.confirm
    user
  }
end
