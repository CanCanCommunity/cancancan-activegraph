require 'dotenv'
Dotenv.load

if ENV['COVERAGE'] || ENV['CI']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
  end
end

require 'bundler/setup'
require 'cancancan/activegraph'

require 'cancan/matchers'

require 'active_graph/core/driver'
require 'active_graph/core'

require 'pry'
# I8n setting to fix deprecation.
if defined?(I18n) && I18n.respond_to?('enforce_available_locales=')
  I18n.enforce_available_locales = false
end

# Add support to load paths
$LOAD_PATH.unshift File.expand_path('../support', __FILE__)
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# DB Driver for tests
class TestDriver < ActiveGraph::Core::Driver
  cattr_reader :cache, default: {}

  at_exit do
    close_all
  end

  class << self
    def new_instance(url, auth_token, options = {})
      cache[url] ||= super(url, auth_token, options.merge(encryption: false))
    end

    def close_all
      cache.values.each(&:close)
    end
  end

  def close; end
end

server_url = ENV['NEO4J_URL'] || 'bolt://localhost:7472'
ActiveGraph::Base.driver = TestDriver.new(server_url)


RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.mock_with :rspec
  config.order = 'random'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    ActiveGraph::ModelSchema::MODEL_INDEXES.clear
    ActiveGraph::ModelSchema::MODEL_CONSTRAINTS.clear
    ActiveGraph::ModelSchema::REQUIRED_INDEXES.clear
    ActiveGraph::Node.loaded_classes.clear
    ActiveGraph::ModelSchema.reload_models_data!
  end
end

$expect_queries_count = 0
ActiveGraph::Transaction.subscribe_to_query do |_message|
  $expect_queries_count += 1
end
