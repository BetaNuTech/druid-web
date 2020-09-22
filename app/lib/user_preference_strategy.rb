class UserPreferenceStrategy < Flipflop::Strategies::AbstractStrategy
  class << self
    def default_description
      'Allows configuration of features per user.'
    end
  end

  def switchable?
    # Can only switch features on/off if we have the user's session.
    # The `request` method is provided by AbstractStrategy.
    request?
  end

  def enabled?(feature)
    # Can only check features if we have the user's session.
    return unless request?
    user = find_current_user or return
    user.feature_enabled?(feature)
  end

  def switch!(feature, enabled)
    user = find_current_user or return
    user.switch_feature!(feature, enabled)
  end

  def clear!(feature)
    user = find_current_user or return
    user.clear_feature!(feature)
  end

  private

  def find_current_user
    # The `request` method is provided by AbstractStrategy.
    return false unless request
    user_id = request.session['warden.user.user.key']&.first&.first
    User.find_by_id(user_id) rescue false
  end
end
