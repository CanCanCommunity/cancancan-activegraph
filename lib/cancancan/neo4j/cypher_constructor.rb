require 'cancancan/neo4j/cypher_constructor_helper'
require 'cancancan/neo4j/association_conditions'

module CanCanCan
  module Neo4j
    # Constructs cypher query from rule cypher options
    class CypherConstructor
      attr_reader :query

      def initialize(rule_cyphers)
        @query = rule_cyphers.first.options[:model_class].new_query
        construct_cypher(rule_cyphers)
      end

      def construct_cypher(rule_cyphers)
        rule_cyphers.each_with_index do |rule_cypher, index|
          if rule_cypher.options[:rule].base_behavior
            construct_can_cypher(rule_cypher, index)
          else
            construct_cannot_cypher(rule_cypher, index)
          end
        end
        unwind_query_with_distinct(rule_cyphers.first.options[:model_class])
      end

      def unwind_query_with_distinct(model_class)
        var = CanCanCan::Neo4j::CypherConstructorHelper.var_name(model_class)
        @query = @query.unwind("#{@current_collection} as #{var}_can")
                       .with("DISTINCT #{var}_can as #{var}")
      end

      def construct_can_cypher(rule_cypher, index)
        with_clause = with_clause_for_rule(rule_cypher, index, true)
        @query = @query.optional_match(rule_cypher.path)
                       .where(rule_cypher.rule_conditions)
                       .with(with_clause)
      end

      def with_clause_for_rule(rule_cypher, index, can_rule)
        var = rule_cypher.options[:var_label]
        with = "collect(DISTINCT #{var}) as #{var}_col"
        with = @current_collection + ' + ' + with if can_rule && @current_collection
        @current_collection = "#{var}_col"
        with
      end

      def construct_cannot_cypher(rule_cypher, index)
        var = rule_cypher.options[:var_label]
        @query = @query.match(rule_cypher.path)
                       .where_not(rule_cypher.rule_conditions)
        @query = @query.where("#{var} IN #{@current_collection}") if @current_collection
        with_claus = with_clause_for_rule(rule_cypher, index, false)
        @query = @query.with(with_claus)
      end
    end
  end
end
