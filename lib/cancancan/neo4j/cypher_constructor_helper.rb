module CanCanCan
  module Neo4j
    # Cypher query constructs
    class CypherConstructorHelper
      class << self
        def var_name(class_constant)
          class_constant.name.downcase.split('::').join('_')
        end

        def path_node(target_class, var_label)
          label = target_class.mapped_label_names
                              .map { |label_name| ":`#{label_name}`" }
                              .join
          "(#{var_label}#{label})"
        end

        def variable_in_path?(relationship, conditions)
          boolean = [TrueClass, FalseClass].include?(conditions.class)
          return false if conditions.blank? || boolean
          !relationship.target_class
                       .associations[conditions.keys.first]
                       .present?
        end

        def path_end_var(relationship, conditions)
          with_var = variable_in_path?(relationship, conditions)
          target_class = relationship.target_class
          var_label = with_var ? var_name(target_class) : ''
        end
      end
    end
  end
end
