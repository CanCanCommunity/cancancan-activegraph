require 'cancancan/active_graph/cypher_constructor_helper'
require 'cancancan/active_graph/rule_cypher'
require 'cancancan/active_graph/cypher_constructor'
require 'cancancan/active_graph/single_rule_cypher'

module CanCan
  module ModelAdapters
    # neo4j adapter for cancan
    class ActiveGraphAdapter < AbstractAdapter
      def database_records
        return @model_class.where('false') if @rules.empty?
        override_scope
        if (rule = logical_single_can_rule)
          return records_for_single_rule(rule)
        end
        records_for_multiple_rules.distinct
      end

      def self.for_class?(model_class)
        model_class <= ActiveGraph::Node
      end

      def self.override_conditions_hash_matching?(_subject, _conditions)
        true
      end

      def self.matches_conditions_hash?(subject, conditions)
        base_class = subject.class
        all_conditions_match?(subject, conditions, base_class)
      end

      def self.all_conditions_match?(subject, conditions, base_class)
        return false unless subject
        conditions.all? do |key, value|
          if (relation = base_class.associations[key])
            match_relation_conditions(value, subject, relation)
          else
            property_matches?(subject, key, value)
          end
        end
      end

      def self.property_matches?(subject, property, value)
        if subject.is_a?(ActiveGraph::Node::HasN::AssociationProxy)
          subject.where(property => value).exists?
        else
          subject.send(property) == value
        end
      end

      def self.match_relation_conditions(conditions, subject, association)
        rel_length = conditions.delete(:rel_length) if conditions.is_a?(Hash)
        subject = subject.send(association.name, rel_length: rel_length)
        return !subject.exists? if conditions.blank?
        return subject.exists? if conditions == true
        all_conditions_match?(subject, conditions, association.target_class)
      end

      private

      def logical_single_can_rule
        return @rules.first if @rules.size == 1
        return unless @rules.all?(&:base_behavior)
        @rules.find do |rule|
          conditions = rule.conditions
          conditions.is_a?(Hash) && conditions.blank?
        end
      end

      def records_for_single_rule(rule)
        CanCanCan::ActiveGraph::SingleRuleCypher.new(rule, @model_class)
                                          .records
      end

      def records_for_multiple_rules
        con = CanCanCan::ActiveGraph::CypherConstructor.new(construct_cypher_options)
        if (scope = con.scope)
          return scope
        end
        con.query.proxy_as(@model_class, var_name)
      end

      def construct_cypher_options
        @rules.reverse.collect.with_index do |rule, index|
          opts = { rule: rule, model_class: @model_class, index: index }
          CanCanCan::ActiveGraph::RuleCypher.new(opts)
        end
      end

      def override_scope
        conditions = @rules.map(&:conditions).compact
        return unless conditions.any? do |condition|
          condition.is_a?(ActiveGraph::Node::Query::QueryProxy)
        end
        return if conditions.size == 1
        return if conditions.select { |cn| cn.is_a?(Hash) && !cn.empty? }.empty?
        raise_override_scope_error
      end

      def raise_override_scope_error
        rule_found = @rules.detect do |rule|
          rule.conditions.is_a?(ActiveGraph::Node::Query::QueryProxy)
        end
        raise Error,
              'Unable to merge an ActiveNode scope with other conditions. '\
              "Instead use a hash for #{rule_found.actions.first}"\
              " #{rule_found.subjects.first} ability."
      end

      def var_name
        CanCanCan::ActiveGraph::CypherConstructorHelper.var_name(@model_class)
      end
    end
  end
end

module ActiveGraph
  module Node
    # simplest way to add `accessible_by` to all ActiveNode models
    module ClassMethods
      include CanCan::ModelAdditions::ClassMethods
    end
  end
end
