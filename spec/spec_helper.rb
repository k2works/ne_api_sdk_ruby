$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ne_api_sdk_ruby'
require 'rack/test'
require 'rspec'
require 'launchy'
require 'ne_api_sdk_ruby/sample_app'

#File.expand_path '../../bin', __FILE__

ENV['RACK_ENV'] = 'test'

module RSpecMixin
  include Rack::Test::Methods
  def app() SampleApp end
end

# For RSpec 2.x
RSpec.configure { |c| c.include RSpecMixin }