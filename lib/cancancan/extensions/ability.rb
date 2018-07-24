module CanCanCan
  module Extensions
    # orverwriting .relevant_rules_for_match method from CanCan::Ability module
    module Ability
      # original method, to want to make scope work with rule like
      # "can :read, Article, Article.where(secret: true)",
      # we are skipping raising of error in case of rule being raw query
      # def relevant_rules_for_match(action, subject)
      #   relevant_rules(action, subject).each do |rule|
      #     next unless rule.only_raw_sql?
      #     raise Error,
      #           "The can? and cannot? call cannot be used with a raw sql."
      #   end
      # end
      def relevant_rules_for_match(action, subject)
        relevant_rules(action, subject)
      end
    end
  end
end

CanCan::Ability.module_eval do
  include CanCanCan::Extensions::Ability
end
