# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'end_state/version'

Gem::Specification.new do |spec|
  spec.name          = 'end_state'
  spec.version       = EndState::VERSION
  spec.authors       = ['alexpeachey']
  spec.email         = ['alex.peachey@gmail.com']
  spec.summary       = 'A State Machine implementation'
  spec.description   = 'A modular state machine with single responsibilities.'
  spec.homepage      = 'https://github.com/Originate/end_state'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
end
