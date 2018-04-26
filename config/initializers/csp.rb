SecureHeaders::Configuration.default do |config|
  config.cookies = {
    secure: true,
    httponly: true,
    samesite: { strict: true }
  }
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "1; mode=block"
  config.csp = {
    default_src: Rails.env.production? ? %w(https: 'self') :  %w(http: 'self' 'unsafe-inline'),
    connect_src: %w('self'),
    font_src: Rails.env.production? ? %w(https: 'self') :  %w(http: 'self'),
    img_src: Rails.env.production? ? %w(https: 'self') :  %w(http: 'self'),
    object_src: %w('none'),
    script_src: Rails.env.production? ? %w(https: 'unsafe-eval') :  %w(http: 'unsafe-eval'),
    style_src: Rails.env.production? ? %w(https: 'self' 'unsafe-inline') :  %w(http: 'self' 'unsafe-inline')
  }
end