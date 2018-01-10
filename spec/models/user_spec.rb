# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string
#  failed_attempts        :integer          default(0), not null
#  unlock_token           :string
#  locked_at              :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  role_id                :uuid
#

require 'rails_helper'

RSpec.describe User, type: :model do
  include_context "users"

  it "can be created" do
    user = build(:user)
    assert(user.save)
  end

  describe "role" do
    it "can be an administrator" do
      assert administrator.administrator?
      refute administrator.agent?
      refute agent.administrator?
    end

    it "can be an operator" do
      assert operator.operator?
      refute agent.operator?
    end

    it "can be an agent" do
      assert agent.agent?
      refute agent.operator?
      refute agent.administrator?
    end
  end


end
