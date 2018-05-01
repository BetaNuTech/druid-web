if Rails.env.production?
  Liquid::Template.error_mode = :strict
else
  Liquid::Template.error_mode = :warn
end
