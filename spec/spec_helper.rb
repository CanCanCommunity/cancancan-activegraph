require 'dotenv'
Dotenv.load

if ENV['COVERAGE'] || ENV['CI']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
  end
end

require 'bundler/setup'
require 'cancancan/neo4j'

require 'cancan/matchers'

require 'neo4j/core/driver'
require 'neo4j/core'

require 'pry'
# I8n setting to fix deprecation.
if defined?(I18n) && I18n.respond_to?('enforce_available_locales=')
  I18n.enforce_available_locales = false
end

# Add support to load paths
$LOAD_PATH.unshift File.expand_path('../support', __FILE__)
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# DB Driver for tests
class TestDriver < Neo4j::Core::Driver
  cattr_reader :cache, default: {}

  at_exit do
    close_all
  end

  default_url('bolt://neo4:neo4j@localhost:7687')

  validate_uri do |uri|
    uri.scheme == 'bolt'
  end

  class << self
    def new_instance(url, options = {})
      cache[url] ||= super(url, options.merge(encryption: false))
    end

    def close_all
      cache.values.each(&:close)
    end
  end

  def close; end
end

server_url = ENV['NEO4J_URL'] || 'bolt://localhost:7472'
Neo4j::ActiveBase.driver = TestDriver.new(server_url)


RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.mock_with :rspec
  config.order = 'random'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    Neo4j::ModelSchema::MODEL_INDEXES.clear
    Neo4j::ModelSchema::MODEL_CONSTRAINTS.clear
    Neo4j::ModelSchema::REQUIRED_INDEXES.clear
    Neo4j::ActiveNode.loaded_classes.clear
    Neo4j::ModelSchema.reload_models_data!
  end
end

$expect_queries_count = 0
Neo4j::Transaction.subscribe_to_query do |_message|
  $expect_queries_count += 1
end
