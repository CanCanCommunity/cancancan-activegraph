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

require 'active_graph/core'
require 'active_graph'

require 'pry'
# I8n setting to fix deprecation.
if defined?(I18n) && I18n.respond_to?('enforce_available_locales=')
  I18n.enforce_available_locales = false
end

# Add support to load paths
$LOAD_PATH.unshift File.expand_path('../support', __FILE__)
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

def set_default_driver
  server_url = ENV['NEO4J_URL'] || 'bolt://localhost:7687'
  ActiveGraph::Base.driver =
    Neo4j::Driver::GraphDatabase.driver(server_url, Neo4j::Driver::AuthTokens.basic('neo4j', 'password'), encryption: false)
end

set_default_driver

def delete_db(executor = ActiveGraph::Base)
  executor.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')
end

def delete_schema
  ActiveGraph::Core::Label.drop_constraints
  ActiveGraph::Core::Label.drop_indexes
end

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

  config.before(:all) do
    ActiveGraph::Config[:id_property] = ENV['NEO4J_ID_PROPERTY'].try :to_sym
  end

  config.before(:each) do
    delete_db
    delete_schema
    @base_logger = spy('Base logger')
    allow(ActiveGraph::Base).to receive(:logger).and_return(@base_logger)
  end
end

$expect_queries_count = 0
ActiveGraph::Base.subscribe_to_query do |_message|
  $expect_queries_count += 1
end
