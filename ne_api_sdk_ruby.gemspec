# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ne_api_sdk_ruby/version'

Gem::Specification.new do |spec|
  spec.name          = "ne_api_sdk_ruby"
  spec.version       = NeApiSdkRuby::VERSION
  spec.authors       = ["k2works"]
  spec.email         = ["kakimomokuri@gmail.com"]
  spec.summary       = %q{NextEngineAPI SDK for Ruby.}
  spec.description   = %q{NextEngineAPI SDK for Ruby.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday",      "~> 0.9.0"
  spec.add_dependency "faraday_middleware", "~> 0.9.1"
  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "yard", "~> 0.8"
  spec.add_development_dependency "redcarpet", "~> 2.2"
  spec.add_development_dependency "pry", "~> 0.10.1"
  spec.add_development_dependency "rspec"
end
