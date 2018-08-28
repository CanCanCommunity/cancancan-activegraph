CanCan::ConditionsMatcher.module_eval do
  private

  def matches_non_block_conditions(subject)
    if @conditions.is_a?(Hash)
      return nested_subject_matches_conditions?(subject) if subject.class == Hash
      return matches_conditions_hash?(subject) unless subject_class?(subject)
    end
    if @conditions.is_a?(::Neo4j::ActiveNode::Query::QueryProxy) || @conditions.is_a?(::Neo4j::ActiveNode::HasN::AssociationProxy)
      return @conditions.where(id: subject.id).exists? unless subject_class?(subject)
    end
    # Don't stop at "cannot" definitions when there are conditions.
    conditions_empty? ? true : @base_behavior
  end
end
