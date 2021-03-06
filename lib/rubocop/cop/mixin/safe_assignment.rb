# encoding: utf-8

module RuboCop
  module Cop
    # Common functionality for safe assignment. By safe assignment we mean
    # putting parentheses around an assignment to indicate "I know I'm using an
    # assignment as a condition. It's not a mistake."
    module SafeAssignment
      extend NodePattern::Macros

      def_node_matcher :safe_assignment?,
                       '(begin {equals_asgn? asgn_method_call?})'

      def safe_assignment_allowed?
        cop_config['AllowSafeAssignment']
      end
    end
  end
end
