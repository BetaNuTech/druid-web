if ENV.fetch('NO_TEST_COVERAGE','') == 'true'
  # See Guardfile cmd: to toggle this option when running with Guard
  # Coverage is disabled because Guard will run partial tests
  puts "*** Skipping Test Coverage Report"
else
  # SimpleCov for coverage reports at coverage/index.html
  require 'simplecov'
  SimpleCov.start 'rails'
end
