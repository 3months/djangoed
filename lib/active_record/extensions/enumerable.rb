module ActiveRecord
  module Extensions
    module Enumerable

      module ClassMethods

        def currently_used_values(column_name, options = {})
          return find(:all, options.merge(
              :select => "DISTINCT #{table_name}.#{column_name}",
              :conditions => "#{table_name}.#{column_name} IS NOT NULL"
            )
          )
        end

      end

      module InstanceMethods
        # Enumerables need to be validated for correctness - if they fail, set to default
        def validate_enumerables
          # for each enumerable - test that the value is in the allowed list and set to the
          # default if it is not
          self.class::ENUMERABLES.each do |key, value|
            if self.respond_to?(key)
              self[key] = value.first unless value.include?(self.send(key))
            end
          end
          return true
        end
      end

    end
  end
end