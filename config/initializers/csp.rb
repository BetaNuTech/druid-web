SecureHeaders::Configuration.default do |config|
  config.cookies = {
    secure: true,
    httponly: true,
    samesite: { strict: true }
  }
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "1; mode=block"
  config.referrer_policy = %w(same-origin)
  config.csp = {
    default_src: Rails.env.production? ? %w(https: 'self') :  %w(http: 'self' 'unsafe-inline'),
    connect_src: Rails.env.production? ? %w('self') : %w('self' http://localhost:3035 ws://localhost:3035 https://apm.scoutapp.com),
    font_src: Rails.env.production? ? %w(https: 'self') :  %w(http: 'self'),
    img_src: Rails.env.production? ? %w(https: 'self') :  %w(http: 'self'),
    object_src: %w('none'),
    script_src: Rails.env.production? ? %w(https: 'unsafe-inline') :  %w(http: 'unsafe-eval' 'unsafe-inline' ),
    style_src: Rails.env.production? ? %w(https: 'self' 'unsafe-inline') :  %w(http: 'self' 'unsafe-inline')
  }
end
