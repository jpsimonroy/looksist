# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'looksist/version'

Gem::Specification.new do |spec|
  spec.name          = 'looksist'
  spec.version       = Lookist::VERSION
  spec.authors       = %w(RC Simon)
  spec.email         = %w(rmchandru@thoughtworks.com simonroy@thoughtworks.com)
  spec.summary       = %q{Redis backed lookup for your models}
  spec.description   = %q{Redis backed lookup for your models}
  spec.homepage      = 'https://github.com/jpsimonroy/herdis'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'activesupport'
  spec.add_development_dependency 'activemodel'
  spec.add_development_dependency 'her'
  spec.add_development_dependency 'cucumber'
  spec.add_development_dependency 'redis'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'coveralls'

  spec.add_runtime_dependency 'jsonpath', '~> 0.5.6'

end
