# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sps_king/version'

Gem::Specification.new do |s|
  s.name          = 'sps_king'
  s.version       = SPS::VERSION
  s.authors       = ['Tobias Schoknecht']
  s.email         = ['tobias.schoknecht@viafintech.com']
  s.description   = 'Implemention of pain.001.001.03.ch.02 and pain.008.001.02.ch.03 (ISO 20022)'
  s.summary       = 'Ruby gem for creating SPS XML files'
  s.homepage      = 'http://github.com/Barzahlen/sps_king'
  s.license       = 'MIT'

  s.files         = `git ls-files`.split($/)
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 2.1'

  s.add_runtime_dependency 'activemodel', '>= 3.1'
  s.add_runtime_dependency 'nokogiri'
  s.add_runtime_dependency 'iban-tools'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'coveralls'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'rake'
end
