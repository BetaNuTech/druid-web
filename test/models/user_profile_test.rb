# == Schema Information
#
# Table name: user_profiles
#
#  id               :uuid             not null, primary key
#  user_id          :uuid
#  name_prefix      :string
#  first_name       :string
#  last_name        :string
#  name_suffix      :string
#  slack            :string
#  cell_phone       :string
#  office_phone     :string
#  fax              :string
#  notes            :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  signature        :text
#  enabled_features :jsonb
#  appsettings      :jsonb
#

require 'test_helper'

class UserProfileTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
