Warden::Manager.after_set_user do |user,auth,opts|
  auth.cookies.encrypted["user_id"] = user.id
  auth.cookies.encrypted["user_expires_at"] = 30.minutes.from_now
end

Warden::Manager.before_logout do |user, auth, opts|
  scope = opts[:scope]
  auth.cookies.encrypted["user_id"] = nil
  auth.cookies.encrypted["user_expires_at"] = nil
end
