module ActionController
  module Extensions
    module Base

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        def got_djangoed(options = {})
          include ActionController::Extensions::Base::InstanceMethods
          extend ActionController::Extensions::Base::SingletonMethods

          include ActionController::Extensions::Actions::InstanceMethods
          #extend ActionController::Extensions::Actions::ClassMethods

          include ActionController::Extensions::RecordSelect::InstanceMethods
          #extend ActionController::Extensions::RecordSelect::ClassMethods

          cattr_accessor :config_options
          self.config_options = {}
          self.config_options[:audit_trail] = options[:audit_trail] if options[:audit_trail].is_a?(Symbol)
          self.config_options[:model_scope_method] = options[:model_scope_method] if options[:model_scope_method].is_a?(Symbol)

          # include the admin interfaces view helpers
          ActionView::Base.send :include, ActionView::Extensions::Base
          helper 'admin/management'

        end

      end

      module InstanceMethods

        private

          ###
          # Shared admin accessor/helper methods
          #
          def model_class
            return @model_class || self.class.model_class
          end
          def model
            instance_variable_get("@#{model_symbol}")
          end
          def model=(object)
            instance_variable_set("@#{model_symbol}", object)
          end
          def models
            instance_variable_get("@#{plural_model_symbol}")
          end
          def models=(objects)
            instance_variable_set("@#{plural_model_symbol}", objects)
          end
          def model_name
            model_class.name
          end
          def plural_model_name
            model_name.pluralize
          end
          def model_symbol
            model_name.sub(/^Admin::/, '').underscore.intern
          end
          def plural_model_symbol
            model_name.sub(/^Admin::/, '').pluralize.underscore.intern
          end
          def humanized_model_name
            model_name.underscore.humanize
          end
          def model_scope_name
            self.class.config_options[:model_scope_method] || (self.class.name.gsub(/::/, '').underscore + '_scope').intern
          end
          #
          # End shared admin accessor/helper methods
          ###

          def remember_last_visited_record(record)
            session[:last_admin_edited] = record.id if record.respond_to?(:id)
          end

          def redirect_to_last_index_or_back
            if session[:last_admin_index]
              redirect_to(session[:last_admin_index])
              session[:last_admin_index] = nil
            elsif request.env["HTTP_REFERER"]
              redirect_to(request.env["HTTP_REFERER"])
            else
              redirect_to('/')
            end
          end

      end

      module SingletonMethods

        def model_class(model_class = nil)
          @model_class = model_class.name.camelize.constantize unless model_class.nil?
          @model_class
        end

        # default_list_order
        #
        # Should be overloaded by the subclass.  Array containing the default order
        # key and the default order direction.  MUST be in that order, eg:
        #
        # ['created', 'desc']
        #
        def default_list_order
          return nil
        end

        def can_disable_pagination?
          return false
        end

        def can_export_csv?
          return false
        end

      end
    end
  end
end

ActionController::Base.send(:include, ActionController::Extensions::Base)
