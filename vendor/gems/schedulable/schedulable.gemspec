# -*- encoding: utf-8 -*-
# stub: schedulable 0.0.10 ruby lib

Gem::Specification.new do |s|
  s.name = "schedulable".freeze
  s.version = "0.0.10".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Rafael Nowrotek".freeze]
  s.date = "2015-11-19"
  s.description = "Handling recurring events in rails.".freeze
  s.email = ["mail@benignware.com".freeze]
  s.homepage = "http://github.com/benignware".freeze
  s.rubygems_version = "2.2.2".freeze
  s.summary = "Handling recurring events in rails.".freeze

  s.installed_by_version = "3.6.9".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<rails>.freeze, [">= 4.0.3".freeze])
  s.add_runtime_dependency(%q<ice_cube>.freeze, [">= 0".freeze])
end
