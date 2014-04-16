# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'end_state_matchers/version'

Gem::Specification.new do |spec|
  spec.name          = 'end_state_matchers'
  spec.version       = EndStateMatchers::VERSION
  spec.authors       = ['alexpeachey']
  spec.email         = ['alex.peachey@gmail.com']
  spec.summary       = 'Custom RSpec Matchers For EndState State Machines'
  spec.description   = 'Custom RSpec Matchers For EndState State Machines'
  spec.homepage      = 'https://github.com/Originate/end_state_matchers'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'rspec', '~> 2.14'
  spec.add_dependency 'end_state'

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake'
end
