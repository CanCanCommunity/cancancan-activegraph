module CanCanCan
  module Neo4j
    # Cypher query constructs
    class CypherConstructorHelper
      class << self
        def var_name(class_constant)
          class_constant.name.downcase.split('::').join('_')
        end

        def path_node(target_class, var_label)
          '(' + var_label + target_class.mapped_label_names.map { |label_name| ":`#{label_name}`" }.join + ')'
        end

        def variable_in_path?(relationship, conditions)
          return false if conditions.blank? || [TrueClass, FalseClass].include?(conditions.class)
          !relationship.target_class.associations[conditions.keys.first].present?
        end

        def path_end_node(relationship, conditions)
          with_var = variable_in_path?(relationship, conditions)
          var_label = with_var ? var_name(relationship.target_class) : ''
          path_node(relationship.target_class, var_label)
        end
      end
    end
  end
end
