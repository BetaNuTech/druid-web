RSpec.shared_context "users" do
  let(:unroled_user) {
    user = create(:user)
    user.confirm
    user.save
    user
  }
end
