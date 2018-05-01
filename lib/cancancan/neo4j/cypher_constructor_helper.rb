module CanCanCan
  module Neo4j
    # Cypher query constructs
    class CypherConstructorHelper
      class << self
        def match_node_cypher(node_class)
          "(#{var_name(node_class)}:`#{node_class.mapped_label_name}`)"
        end

        def construct_conditions_string(conditions_hash, base_class, path = '')
          variable_name = var_name(base_class)
          conditions_hash.collect do |key, value|
            condition = if base_class.associations_keys.include?(key)
                          con = condtion_for_path(path: path,
                                                  variable_name: variable_name,
                                                  base_class: base_class,
                                                  key: key)
                          value ? con : ' NOT ' + con
                        elsif key == :id
                          condition_for_id(base_class, variable_name, value)
                        else
                          condition_for_attribute(value, variable_name, key)
                        end
            '(' + condition + ')'
          end.join(' AND ')
        end

        def condition_for_attribute(value, variable_name, attribute)
          lhs = variable_name + '.' + attribute.to_s
          return lhs + ' IS NULL ' if value.nil?
          rhs = value.to_s
          rhs = "'" + rhs + "'" unless [true, false].include?(value)
          lhs + '=' + rhs
        end

        def condtion_for_path(path:, variable_name:, base_class:, key:)
          path = "(#{variable_name})" if path.blank?
          relationship = base_class.associations[key]
          path + relationship.arrow_cypher + path_end_node(relationship)
        end

        def condition_for_id(base_class, variable_name, value)
          id_property = base_class.id_property_name
          if id_property == :neo_id
            "ID(#{variable_name})=#{value}"
          else
            variable_name + '.' + id_property.to_s + '=' + "'#{value}'"
          end
        end

        def var_name(class_constant)
          class_constant.name.downcase.split('::').join('_')
        end

        def bifurcate_conditions(conditions)
          conditions.partition { |_, value| value.is_a?(Hash) }.map(&:to_h)
        end

        def append_and_or_to_conditions(cypher_options, rule_cypher)
          conditions_string = cypher_options[:conditions]
          connector = if conditions_string.blank?
                        ''
                      else
                        rule_cypher.conditions_connector
                      end
          connector += 'NOT' if rule_cypher.append_not_to_conditions?
          cypher_options[:conditions] = conditions_string + connector
        end

        def path_end_node(relationship)
          '(' + relationship.target_class.mapped_label_names.map { |label_name| ":`#{label_name}`" }.join + ')'
        end
      end
    end
  end
end
