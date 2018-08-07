require 'cancancan/neo4j/cypher_constructor_helper'

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
        model_class = @options[:model_class]
        var_label = CypherConstructorHelper.var_name(model_class)
        var_label += index_sub_str
        @options[:var_label] = var_label
        @path = CypherConstructorHelper.path_node(model_class, var_label)
      end

      def construct_cypher_conditions
        conditions = @options[:rule].conditions
        if conditions.is_a?(::Neo4j::ActiveNode::Query::QueryProxy)
          return @options[:scope] = conditions
        end
        if conditions.blank?
          condition_for_rule_without_conditions
        else
          construct_cypher_options
        end
      end

      private

      def index_sub_str
        index = @options[:index]
        return '' unless index
        ('_' + (@options[:index] + 1).to_s)
      end

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
        if (rel = base_class.associations[key])
          update_path_with_rel(conditions, rel)
          cypher_for_relation_conditions(conditions, rel)
        else
          merge_conditions(key, conditions, base_class)
        end
      end

      def update_path_with_rel(conditions, rel)
        rel_length = conditions.delete(:rel_length) if conditions
        arrow_cypher = rel.arrow_cypher(nil, {}, false, false, rel_length)
        node_label = CypherConstructorHelper.path_end_node(rel, conditions)
        @path += (arrow_cypher + node_label)
      end

      def cypher_for_relation_conditions(conditions, relationship)
        if conditions.is_a?(Hash)
          conditions.each do |key, con|
            hash_cypher_options(key, con, relationship.target_class)
          end
        else
          update_conditions_with_path(conditions ? '' : 'NOT ')
        end
      end

      def update_conditions_with_path(not_str)
        @rule_conditions = not_str + @path
        initialize_path
      end

      def merge_conditions(key, value, base_class)
        var_name = var_label_for_conditions(base_class, key)
        if key == :id
          merge_condition_for_id(var_name, base_class, value)
        else
          (@rule_conditions[var_name] ||= {}).merge!(key => value)
        end
      end

      def var_label_for_conditions(base_class, key)
        condition_keys = @options[:rule].conditions.keys
        return @options[:var_label] if condition_keys.include?(key)
        CypherConstructorHelper.var_name(base_class)
      end

      def merge_condition_for_id(var_name, base_class, value)
        id_property_name = base_class.id_property_name
        if id_property_name == :neo_id
          @rule_conditions.merge!("ID(#{var_name})" => value)
        else
          (@rule_conditions[var_name] ||= {}).merge!(id_property_name => value)
        end
      end
    end
  end
end
