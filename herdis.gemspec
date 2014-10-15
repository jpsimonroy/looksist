# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'herdis/version'

Gem::Specification.new do |spec|
  spec.name          = 'herdis'
  spec.version       = Herdis::VERSION
  spec.authors       = %w(RC Simon)
  spec.email         = %w(rmchandru@thoughtworks.com simonroy@thoughtworks.com)
  spec.summary       = %q{Redis backed lookup for your her models}
  spec.description   = %q{Redis backed lookup for your her models}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'activesupport'


end
