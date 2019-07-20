$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "core/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "core"
  s.version     = Core::VERSION
  s.authors     = ["William Weckl"]
  s.email       = ["william.weckl@gmail.com"]
  s.homepage    = "https://contas.rdstation.com"
  s.summary     = "Core."
  s.description = "RD Contas core module."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "i18n", "~> 0.8"
  s.add_dependency "dry-struct", "~> 1.0"
  s.add_dependency "dry-transaction", "~> 0.13"
  s.add_dependency "dry-validation", "~> 1.0.0"
  s.add_dependency "activerecord", ">= 4.2.11.1", "< 6.0" # Rails Database ORM
  s.add_dependency "will_paginate", "~> 3.1" # Pagination

  s.add_development_dependency "rspec", "~> 3.8"
  s.add_development_dependency "simplecov", "~> 0.16"
  s.add_development_dependency "fivemat", "~> 1.3"
  s.add_development_dependency "rspec_junit_formatter", "~> 0.4"
end
