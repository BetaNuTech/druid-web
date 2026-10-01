module EnvHelper
  # Set ENV vars for the duration of the block, restoring the old values after.
  def with_env(vars)
    vars = vars.transform_keys(&:to_s)
    old = vars.keys.to_h { |key| [key, ENV[key]] }
    vars.each { |key, value| ENV[key] = value }
    yield
  ensure
    old&.each { |key, value| ENV[key] = value }
  end
end

RSpec.configure do |config|
  config.include EnvHelper
end
