require 'cancancan/neo4j/cypher_constructor_helper'

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
        @query = unwind_qeury("#{var}_can")       
                 .with("DISTINCT #{var}_can as #{var}")
      end

      def unwind_qeury(var_name)
        @query = @query.unwind("#{@current_collection} as #{var_name}")
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
        match_cls = match_clause(rule_cypher)
        unwind_for_cannot(rule_cypher)
        @query = @query.break
                       .match(match_cls)
                       .where_not(rule_cypher.rule_conditions)
        with_claus = with_clause_for_rule(rule_cypher, index, false)
        @query = @query.with(with_claus)
      end

      def unwind_for_cannot(rule_cypher)
        return unless @current_collection.present?
        var = rule_cypher.options[:var_label]
        @query = unwind_qeury(var)
                 .with("DISTINCT #{var} as #{var}")
      end

      def match_clause(rule_cypher)
         var = rule_cypher.options[:var_label]
         @current_collection.present? ? "(#{var})" : rule_cypher.path
      end
    end
  end
end
