require 'rails_helper'

RSpec.describe SignInHelper, type: :helper do
  describe '#password_disclosure_open?' do
    it 'is closed with no alert' do
      expect(helper.password_disclosure_open?).to be(false)
    end

    # Not failures: every logged-out visitor to a protected page gets the first,
    # and every user idle past timeout_in gets the second.
    %w[unauthenticated timeout].each do |key|
      it "is closed for Devise's #{key} prompt" do
        flash[:alert] = I18n.t("devise.failure.#{key}")

        expect(helper.password_disclosure_open?).to be(false)
      end
    end

    it 'is open for a real failure' do
      flash[:alert] = I18n.t('devise.failure.invalid', authentication_keys: 'Email')

      expect(helper.password_disclosure_open?).to be(true)
    end

    it 'is open for a Google refusal' do
      flash[:alert] = 'That email address is already linked to a different Google account.'

      expect(helper.password_disclosure_open?).to be(true)
    end
  end
end
