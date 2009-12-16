module ActiveRecord
  module Extensions
    module ManagedContent

      module ClassMethods

        # build_constant_conditions_hide_withdrawn
        # Need only be defined if you wish to "show withdrawn" and there are
        # constant conditions that should always be applied when without withdrawn
        # content.  If it is defined it MUST be one of the following forms:
        #
        # "<you_conditions_here>"
        # ["<you_conditions_here>"]
        # ["<you_conditions_here>", param1, params2, ....]
        #
        def build_constant_conditions_hide_withdrawn(mode)
          return build_constant_conditions(mode)
        end

        # build_constant_conditions
        # Need only be defined if there are constant conditions that should
        # always be applied.  If it is defined it MUST be one of the following
        # forms:
        #
        # "<you_conditions_here>"
        # ["<you_conditions_here>"]
        # ["<you_conditions_here>", param1, params2, ....]
        #
        def build_constant_conditions(mode)
          return nil
        end

      end

      module InstanceMethods
        
      end

    end
  end
end