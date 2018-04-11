require 'cancancan/neo4j/cypher_constructor_helper'
require 'cancancan/neo4j/association_conditions'

module CanCanCan
  module Neo4j
    # Constructs cypher conditions for rule and cypher match classes
    class RuleCypher
      attr_reader :rule_conditions, :cypher_matches

      def initialize(options)
        @options = options
        @rule_conditions = ''
        @cypher_matches = []
        construct_cypher_conditions
      end

      def construct_cypher_conditions
        if @options[:rule].conditions.blank?
          condition_for_rule_without_conditions
        else
          set_cypher_options
        end
      end

      def conditions_connector
        @options[:rule].base_behavior ? ' OR ' : ' AND '
      end

      def append_not_to_conditions?
        !rule_conditions_blank? && !@options[:rule].base_behavior
      end

      private

      def rule_conditions_blank?
        @options[:rule].conditions.blank?
      end

      def condition_for_rule_without_conditions
        @rule_conditions = @options[:rule].base_behavior ? '(true)' : '(false)'
      end

      def set_cypher_options
        associations_conditions, model_conditions = CypherConstructorHelper.bifurcate_conditions(@options[:rule].conditions)
        @rule_conditions = CypherConstructorHelper.construct_conditions_string(model_conditions, @options[:model_class], default_path) unless model_conditions.blank?
        return if associations_conditions.blank?
        append_association_conditions(associations_conditions)
      end

      def append_association_conditions(conditions_hash)
        options = { asso_conditions: conditions_hash, parent_class: @options[:model_class], path: default_path }
        asso_conditions_obj = AssociationConditions.new(options)
        @rule_conditions += ' AND ' unless @rule_conditions.blank?
        @rule_conditions += asso_conditions_obj.conditions_string
        @cypher_matches += asso_conditions_obj.cypher_matches
      end

      def default_path
        CypherConstructorHelper.match_node_cypher(@options[:model_class])
      end
    end
  end
end
