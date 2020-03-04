CanCan::ConditionsMatcher.module_eval do
  private

  def matches_non_block_conditions(subject)
    if @conditions.is_a?(Hash)
      return nested_subject_matches_conditions?(subject) if subject.class == Hash
      return matches_conditions_hash?(subject) unless subject_class?(subject)
    end
    if @conditions.is_a?(::ActiveGraph::Node::Query::QueryProxy) || @conditions.is_a?(::ActiveGraph::Node::HasN::AssociationProxy)
      return @conditions.where(id: subject.id).exists? unless subject_class?(subject)
    end
    # Don't stop at "cannot" definitions when there are conditions.
    conditions_empty? ? true : @base_behavior
  end

  def conditions_empty?
    (@conditions.is_a?(Hash) && @conditions == {}) || @conditions.nil?
  end
end
