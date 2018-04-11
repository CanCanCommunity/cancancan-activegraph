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

require 'neo4j-server'
require 'neo4j-embedded' if RUBY_PLATFORM == 'java'

require 'neo4j/core/cypher_session'
require 'neo4j/core/cypher_session/adaptors/http'
require 'neo4j/core/cypher_session/adaptors/bolt'
require 'neo4j/core/cypher_session/adaptors/embedded'
require 'pry'
# I8n setting to fix deprecation.
if defined?(I18n) && I18n.respond_to?('enforce_available_locales=')
  I18n.enforce_available_locales = false
end

# Add support to load paths
$LOAD_PATH.unshift File.expand_path('../support', __FILE__)
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

TEST_SESSION_MODE = RUBY_PLATFORM == 'java' ? :embedded : :http

EMBEDDED_DB_PATH = File.join(Dir.tmpdir, 'neo4j-core-java')

session_adaptor = case TEST_SESSION_MODE
                  when :embedded
                    Neo4j::Core::CypherSession::Adaptors::Embedded.new(EMBEDDED_DB_PATH, impermanent: true, auto_commit: true, wrap_level: :proc)
                  when :http
                    server_url = ENV['NEO4J_URL'] || 'http://localhost:7475'
                    server_username = ENV['NEO4J_USERNAME'] || 'neo4j'
                    server_password = ENV['NEO4J_PASSWORD'] || 'password'

                    basic_auth_hash = {username: server_username, password: server_password}

                    case URI(server_url).scheme
                    when 'http'
                      Neo4j::Core::CypherSession::Adaptors::HTTP.new(server_url, basic_auth: basic_auth_hash, wrap_level: :proc)
                    when 'bolt'
                      Neo4j::Core::CypherSession::Adaptors::Bolt.new(server_url, wrap_level: :proc) # , logger_level: Logger::DEBUG)
                    else
                      fail "Invalid scheme for NEO4J_URL: #{scheme} (expected `http` or `bolt`)"
                    end
                  end

puts session_adaptor
Neo4j::ActiveBase.current_adaptor = session_adaptor


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

