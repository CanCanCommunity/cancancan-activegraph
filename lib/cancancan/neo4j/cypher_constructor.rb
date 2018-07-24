require 'cancancan/neo4j/cypher_constructor_helper'

module CanCanCan
  module Neo4j
    # Constructs cypher query from rule cypher options
    class CypherConstructor
      attr_reader :query, :scope

      def initialize(rule_cyphers)
        @model_class = rule_cyphers.first.options[:model_class]
        reset_variables
        construct_cypher(rule_cyphers)
      end

      def reset_variables
        @query = @model_class.new_query
        @current_collection = nil
      end

      def construct_cypher(rule_cyphers)
        rule_cyphers.each do |rule_cypher|
          construct_cypher_for_rule(rule_cypher)
        end
        unwind_query_with_distinct
      end

      def construct_cypher_for_rule(rule_cypher)
        rule = rule_cypher.options[:rule]
        return if update_scope(rule_cypher)
        reset_variables if rule.conditions.blank?
        if rule.base_behavior
          construct_can_cypher(rule_cypher)
        else
          construct_cannot_cypher(rule_cypher)
        end
      end

      def update_scope(rule_cypher)
        @scope = rule_cypher.options[:scope]
      end

      def unwind_query_with_distinct
        var = CanCanCan::Neo4j::CypherConstructorHelper.var_name(@model_class)
        @query = unwind_qeury("#{var}_can")
                 .with("DISTINCT #{var}_can as #{var}")
      end

      def unwind_qeury(var_name)
        @query = @query.unwind("#{@current_collection} as #{var_name}")
      end

      def construct_can_cypher(rule_cypher)
        with_clause = with_clause_for_rule(rule_cypher, true)
        @query = @query.optional_match(rule_cypher.path)
                       .where(rule_cypher.rule_conditions)
                       .with(with_clause)
      end

      def with_clause_for_rule(rule_cypher, can_rule)
        var = rule_cypher.options[:var_label]
        with = "collect(DISTINCT #{var}) as #{var}_col"
        if can_rule && @current_collection
          with = "#{@current_collection} + #{with}"
        end
        @current_collection = "#{var}_col"
        with
      end

      def construct_cannot_cypher(rule_cypher)
        match_cls = match_clause(rule_cypher)
        unwind_for_cannot(rule_cypher)
        @query = @query.break
                       .match(match_cls)
                       .where_not(rule_cypher.rule_conditions)
        with_claus = with_clause_for_rule(rule_cypher, false)
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
