require 'cancancan/neo4j/cypher_constructor_helper'
require 'cancancan/neo4j/association_conditions'

module CanCanCan
  module Neo4j
    # Constructs cypher conditions for rule and cypher match classes
    class RuleCypher
      attr_reader :rule_conditions, :path, :options

      def initialize(options)
        @options = options
        @rule_conditions = {}
        initialize_path
        construct_cypher_conditions
      end

      def initialize_path
        var_label = CypherConstructorHelper.var_name(@options[:model_class])
        var_label += ('_' + (@options[:index] + 1).to_s)
        @options[:var_label] = var_label
        @path = CypherConstructorHelper.path_node(@options[:model_class], var_label)
      end

      def construct_cypher_conditions
        if @options[:rule].conditions.blank?
          condition_for_rule_without_conditions
        else
          construct_cypher_options
        end
      end

      private

      def rule_conditions_blank?
        @options[:rule].conditions.blank?
      end

      def condition_for_rule_without_conditions
        @rule_conditions = @options[:rule].base_behavior ? '(true)' : '(false)'
      end

      def construct_cypher_options
        @options[:rule].conditions.deep_dup.each do |key, conditions|
          hash_cypher_options(key, conditions, @options[:model_class])
        end
      end

      def hash_cypher_options(key, conditions, base_class)
        if (relationship = base_class.associations[key])
          rel_length = conditions.delete(:rel_length) if conditions
          arrow_cypher = relationship.arrow_cypher(nil, {}, false, false, rel_length)
          to_node_label = CypherConstructorHelper.path_end_node(relationship, conditions)
          @path += (arrow_cypher + to_node_label)
          cypher_for_relation_conditions(conditions, relationship)
        else
          merge_conditions(key, conditions, base_class)
        end
      end

      def cypher_for_relation_conditions(conditions, relationship)
        if conditions.blank? || [TrueClass, FalseClass].include?(conditions.class)
          not_str = conditions ? '' : 'NOT ' 
          @rule_conditions = not_str + @path
          initialize_path
        else
          conditions.each { |key, con| hash_cypher_options(key, con, relationship.target_class) }
        end
      end

      def merge_conditions(key, value, base_class)
        var_name = var_label_for_conditions(base_class, key)
        if key == :id
          merge_condition_for_id(var_name, base_class, value)
        else
          @rule_conditions[var_name] ||= {}
          @rule_conditions[var_name].merge!(key => value)
        end
      end

      def var_label_for_conditions(base_class, key)
        return @options[:var_label] if @options[:rule].conditions.keys.include?(key)
        CypherConstructorHelper.var_name(base_class)
      end

      def merge_condition_for_id(var_name, base_class, value)
        id_property_name = base_class.id_property_name
        if id_property_name == :neo_id
          @rule_conditions.merge!("ID(#{var_name})" => value)
        else
          @rule_conditions[var_name] ||= {}
          @rule_conditions[var_name].merge!(id_property_name => value)
        end
      end
    end
  end
end
