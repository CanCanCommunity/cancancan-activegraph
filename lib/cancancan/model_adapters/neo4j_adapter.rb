require 'cancancan/neo4j/cypher_constructor_helper'
require 'cancancan/neo4j/rule_cypher'

module CanCan
  module ModelAdapters
    # neo4j adapter for cancan
    class Neo4jAdapter < AbstractAdapter
      def database_records
        return @model_class.where('false') if @rules.empty?
        rule = @rules.first
        return rule.conditions if override_scope
        records_for_multiple_rules.distinct
      end

      def self.for_class?(model_class)
        model_class <= Neo4j::ActiveNode
      end

      def self.override_conditions_hash_matching?(_subject, _conditions)
        true
      end

      def self.matches_conditions_hash?(subject, conditions)
        base_class = subject.class
        all_conditions_match?(subject, conditions, base_class)
      end

      def self.all_conditions_match?(subject, conditions, base_class)
        asso_conditions, model_conditions = CanCanCan::Neo4j::CypherConstructorHelper
                                            .bifurcate_conditions(conditions)
        associations_conditions_match?(asso_conditions, subject, base_class) &&
          model_conditions_matches?(model_conditions, subject, base_class)
      end

      def self.model_conditions_matches?(conditions, subject, base_class)
        return true if conditions.blank?
        conditions = conditions.partition do |key, _|
          base_class.associations_keys.include?(key)
        end
        associations_conditions, atrribute_conditions = conditions.map(&:to_h)
        matches_attribute_conditions?(atrribute_conditions, subject) &&
          matches_associations_relations(associations_conditions, subject)
      end

      # checks if associations exists on given node
      def self.matches_associations_relations(conditions, subject)
        return true if conditions.blank?
        conditions.all? do |association, value|
          association_exists = subject.send(association).exists?
          value ? association_exists : !association_exists
        end
      end

      def self.matches_attribute_conditions?(conditions, subject)
        return true if conditions.blank?
        if subject.is_a?(Neo4j::ActiveNode::HasN::AssociationProxy)
          subject.where(conditions).exists?
        else
          conditions.all? do |attribute, value|
            subject.send(attribute) == value
          end
        end
      end

      def self.associations_conditions_match?(conditions, subject, base_class)
        return true if conditions.blank?
        conditions.all? do |association, conditions_hash|
          rel_length = conditions_hash.delete(:rel_length)
          current_subject = subject.send(association, rel_length: rel_length)
          return false unless current_subject
          current_model = base_class.associations[association].target_class
          all_conditions_match?(current_subject, conditions_hash, current_model)
        end
      end

      private

      def records_for_multiple_rules
        base_query = base_query_proxy.query
        cypher_options = construct_cypher_options
        match_string = cypher_options[:matches].uniq.join(', ')
        base_query = base_query.match(match_string) unless match_string.blank?
        base_query
          .proxy_as(@model_class, var_name(@model_class))
          .where(cypher_options[:conditions])
      end

      def construct_cypher_options
        default_options = { conditions: '', matches: [] }
        @rules.reverse.each_with_object(default_options) do |rule, options|
          rule_options = { rule: rule, model_class: @model_class }
          rule_cypher = CanCanCan::Neo4j::RuleCypher.new(rule_options)
          CanCanCan::Neo4j::CypherConstructorHelper
            .append_and_or_to_conditions(options, rule_cypher)
          options[:conditions] += ('(' + rule_cypher.rule_conditions + ')')
          options[:matches] += rule_cypher.cypher_matches
          options
        end
      end

      def base_query_proxy
        @model_class.as(var_name(@model_class))
      end

      def override_scope
        conditions = @rules.map(&:conditions).compact
        return unless conditions.any? { |condition| condition.is_a?(Neo4j::ActiveNode::Query::QueryProxy) }
        return conditions.first if conditions.size == 1
        raise_override_scope_error
      end

      def raise_override_scope_error
        rule_found = @rules.detect { |rule| rule.conditions.is_a?(Neo4j::ActiveNode::Query::QueryProxy) }
        raise Error,
              'Unable to merge an ActiveNode scope with other conditions. '\
              "Instead use a hash for #{rule_found.actions.first} #{rule_found.subjects.first} ability."
      end

      def var_name(model_class)
        CanCanCan::Neo4j::CypherConstructorHelper.var_name(model_class)
      end
    end
  end
end

module Neo4j
  module ActiveNode
    # simplest way to add `accessible_by` to all ActiveNode models
    module ClassMethods
      include CanCan::ModelAdditions::ClassMethods
    end
  end
end
