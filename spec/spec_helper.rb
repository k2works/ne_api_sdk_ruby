$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ne_api_sdk_ruby'
require 'json_spec'
require 'dotenv'
Dotenv.load

RSpec.configure do |config|
  config.include JsonSpec::Helpers
  config.include RSpec::RequestDescriber
end