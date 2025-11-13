RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  # Create system user once before all tests run
  config.before(:suite) do
    # Only create if system_user column exists and no system user exists yet
    if User.column_names.include?('system_user') && User.system.nil?
      FactoryBot.create(:system_user)
    end
  end
end

