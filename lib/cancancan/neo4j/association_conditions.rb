require 'cancancan/neo4j/cypher_constructor_helper'

module CanCanCan
  module Neo4j
    # Constructs cypher conditions for associations conditions hash
    class AssociationConditions
      attr_reader :conditions_string, :cypher_matches

      def initialize(options)
        @options = options
        @conditions_string = ''
        @cypher_matches = []
        construct_conditions
      end

      def construct_conditions
        @options[:asso_conditions].each do |association, conditions|
          relationship = association_relation(association)
          associations_conditions, model_conditions = CypherConstructorHelper.bifurcate_conditions(conditions)
          rel_length = associations_conditions.delete(:rel_length)
          current_path = append_path_to_conditions(relationship, model_conditions, rel_length)
          append_model_conditions(model_conditions, relationship, current_path)
          append_association_conditions(associations_conditions, relationship)
        end
      end

      def association_relation(association)
        @options[:parent_class].associations[association]
      end

      def append_association_conditions(conditions, relationship)
        return if conditions.blank?
        asso_conditions_obj = AssociationConditions.new(asso_conditions: conditions, parent_class: relationship.target_class, path: path_with_relationship(relationship))
        append_and_to_conditions_string
        @conditions_string += asso_conditions_obj.conditions_string
        @cypher_matches += asso_conditions_obj.cypher_matches
      end

      def append_path_to_conditions(relationship, model_conditions, rel_length)
        target_class = relationship.target_class
        model_attr_exists = model_conditions.any? do |key, _|
          !target_class.associations_keys.include?(key)
        end
        end_node = model_attr_exists ? CypherConstructorHelper.match_node_cypher(target_class) : '()'
        arrow_cypher = relationship.arrow_cypher(nil, {}, false, false, rel_length)
        current_path = @options[:path] + arrow_cypher + end_node
        if model_attr_exists
          append_matches(relationship)
          append_and_to_conditions_string
          @conditions_string += current_path
        end
        current_path
      end

      def append_matches(relationship)
        node_class = relationship.target_class
        @cypher_matches << CypherConstructorHelper.match_node_cypher(node_class)
      end

      def append_and_to_conditions_string
        @conditions_string += ' AND ' unless @conditions_string.blank?
      end

      def append_model_conditions(model_conditions, relationship, current_path)
        return if model_conditions.blank?
        con_string = CypherConstructorHelper.construct_conditions_string(model_conditions, relationship.target_class, current_path)
        append_and_to_conditions_string
        @conditions_string += con_string
      end

      def path_with_relationship(relationship)
        @options[:path] + relationship.arrow_cypher + '()'
      end
    end
  end
end
