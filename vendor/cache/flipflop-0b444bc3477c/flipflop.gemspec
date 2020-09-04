# -*- encoding: utf-8 -*-
# stub: flipflop 2.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "flipflop".freeze
  s.version = "2.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Paul Annesley".freeze, "Rolf Timmermans".freeze, "Jippe Holwerda".freeze]
  s.date = "2020-09-04"
  s.description = "Declarative API for specifying features, switchable in declaration, database and cookies.".freeze
  s.email = ["paul@annesley.cc".freeze, "rolftimmermans@voormedia.com".freeze, "jippeholwerda@voormedia.com".freeze]
  s.files = [".gitignore".freeze, ".travis.yml".freeze, "CHANGES.md".freeze, "Gemfile".freeze, "LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "app/controllers/flipflop/features_controller.rb".freeze, "app/controllers/flipflop/strategies_controller.rb".freeze, "app/views/flipflop/features/index.html.erb".freeze, "app/views/flipflop/stylesheets/_flipflop.css".freeze, "app/views/layouts/flipflop.html.erb".freeze, "config/features.rb".freeze, "config/locales/en.yml".freeze, "config/routes.rb".freeze, "flipflop.gemspec".freeze, "lib/flipflop.rb".freeze, "lib/flipflop/configurable.rb".freeze, "lib/flipflop/engine.rb".freeze, "lib/flipflop/facade.rb".freeze, "lib/flipflop/feature_cache.rb".freeze, "lib/flipflop/feature_definition.rb".freeze, "lib/flipflop/feature_loader.rb".freeze, "lib/flipflop/feature_set.rb".freeze, "lib/flipflop/group_definition.rb".freeze, "lib/flipflop/strategies/abstract_strategy.rb".freeze, "lib/flipflop/strategies/active_record_strategy.rb".freeze, "lib/flipflop/strategies/cookie_strategy.rb".freeze, "lib/flipflop/strategies/default_strategy.rb".freeze, "lib/flipflop/strategies/lambda_strategy.rb".freeze, "lib/flipflop/strategies/options_hasher.rb".freeze, "lib/flipflop/strategies/query_string_strategy.rb".freeze, "lib/flipflop/strategies/redis_strategy.rb".freeze, "lib/flipflop/strategies/sequel_strategy.rb".freeze, "lib/flipflop/strategies/session_strategy.rb".freeze, "lib/flipflop/strategies/test_strategy.rb".freeze, "lib/flipflop/version.rb".freeze, "lib/generators/flipflop/features/USAGE".freeze, "lib/generators/flipflop/features/features_generator.rb".freeze, "lib/generators/flipflop/features/templates/features.rb".freeze, "lib/generators/flipflop/install/install_generator.rb".freeze, "lib/generators/flipflop/migration/USAGE".freeze, "lib/generators/flipflop/migration/migration_generator.rb".freeze, "lib/generators/flipflop/migration/templates/create_features.rb".freeze, "lib/generators/flipflop/routes/USAGE".freeze, "lib/generators/flipflop/routes/routes_generator.rb".freeze, "lib/tasks/flipflop.rake".freeze, "lib/tasks/support/methods.rb".freeze, "src/stylesheets/_flipflop.scss".freeze, "test/integration/app_test.rb".freeze, "test/integration/dashboard_test.rb".freeze, "test/templates/nl.yml".freeze, "test/templates/test_app_features.rb".freeze, "test/templates/test_engine.rb".freeze, "test/templates/test_engine_features.rb".freeze, "test/test_helper.rb".freeze, "test/unit/configurable_test.rb".freeze, "test/unit/feature_cache_test.rb".freeze, "test/unit/feature_definition_test.rb".freeze, "test/unit/feature_set_test.rb".freeze, "test/unit/flipflop_test.rb".freeze, "test/unit/group_definition_test.rb".freeze, "test/unit/strategies/abstract_strategy_request_test.rb".freeze, "test/unit/strategies/abstract_strategy_test.rb".freeze, "test/unit/strategies/active_record_strategy_test.rb".freeze, "test/unit/strategies/cookie_strategy_test.rb".freeze, "test/unit/strategies/default_strategy_test.rb".freeze, "test/unit/strategies/lambda_strategy_test.rb".freeze, "test/unit/strategies/options_hasher_test.rb".freeze, "test/unit/strategies/query_string_strategy_test.rb".freeze, "test/unit/strategies/redis_strategy_test.rb".freeze, "test/unit/strategies/sequel_strategy_test.rb".freeze, "test/unit/strategies/session_strategy_test.rb".freeze, "test/unit/strategies/test_strategy_test.rb".freeze, "test/unit/strategies_controller_test.rb".freeze, "test/unit/tasks/support/methods_test.rb".freeze]
  s.homepage = "https://github.com/voormedia/flipflop".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "A feature flipflopper for Rails web applications.".freeze
  s.test_files = ["test/integration/app_test.rb".freeze, "test/integration/dashboard_test.rb".freeze, "test/templates/nl.yml".freeze, "test/templates/test_app_features.rb".freeze, "test/templates/test_engine.rb".freeze, "test/templates/test_engine_features.rb".freeze, "test/test_helper.rb".freeze, "test/unit/configurable_test.rb".freeze, "test/unit/feature_cache_test.rb".freeze, "test/unit/feature_definition_test.rb".freeze, "test/unit/feature_set_test.rb".freeze, "test/unit/flipflop_test.rb".freeze, "test/unit/group_definition_test.rb".freeze, "test/unit/strategies/abstract_strategy_request_test.rb".freeze, "test/unit/strategies/abstract_strategy_test.rb".freeze, "test/unit/strategies/active_record_strategy_test.rb".freeze, "test/unit/strategies/cookie_strategy_test.rb".freeze, "test/unit/strategies/default_strategy_test.rb".freeze, "test/unit/strategies/lambda_strategy_test.rb".freeze, "test/unit/strategies/options_hasher_test.rb".freeze, "test/unit/strategies/query_string_strategy_test.rb".freeze, "test/unit/strategies/redis_strategy_test.rb".freeze, "test/unit/strategies/sequel_strategy_test.rb".freeze, "test/unit/strategies/session_strategy_test.rb".freeze, "test/unit/strategies/test_strategy_test.rb".freeze, "test/unit/strategies_controller_test.rb".freeze, "test/unit/tasks/support/methods_test.rb".freeze]

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<activesupport>.freeze, [">= 4.0"])
    s.add_runtime_dependency(%q<terminal-table>.freeze, [">= 1.8"])
  else
    s.add_dependency(%q<activesupport>.freeze, [">= 4.0"])
    s.add_dependency(%q<terminal-table>.freeze, [">= 1.8"])
  end
end
