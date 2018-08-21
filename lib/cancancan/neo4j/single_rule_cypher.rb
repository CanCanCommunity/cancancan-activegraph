require 'cancancan/neo4j/cypher_constructor_helper'

module CanCanCan
  module Neo4j
    # Return records for single cancan rule
    class SingleRuleCypher
      attr_reader :rule, :model_class
      def initialize(rule, model_class)
        @rule = rule
        @model_class = model_class
      end

      def records
        conds = rule.conditions
        return conds if conds.is_a?(::Neo4j::ActiveNode::Query::QueryProxy)
        return records_for_no_conditions if conds.blank?
        records_for_hash_conditions
      end

      private

      def records_for_no_conditions
        if rule.base_behavior
          model_class.all
        else
          model_class.where('false')
        end
      end

      def records_for_hash_conditions
        cypher = CanCanCan::Neo4j::RuleCypher.new(rule: rule,
                                                  model_class: model_class,
                                                  index: nil)
        model_class.new_query
                   .match(cypher.path)
                   .where(cypher.rule_conditions)
                   .proxy_as(model_class, var_lable)
                   .distinct
      end

      def var_lable
        CypherConstructorHelper.var_name(model_class)
      end
    end
  end
end
