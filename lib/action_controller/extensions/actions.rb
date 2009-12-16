module ActionController
  module Extensions
    module Actions

      module InstanceMethods

        # Change ADMIN_LIST_PAGINATION_LENGTH to alter the pagination length on all
        # list pages, unless the were manually overloaded by the subclass
        # ADMIN_LIST_PAGINATION_LENGTH = 10 # default
        ADMIN_LIST_PAGINATION_LENGTH = 10
        PAGINATION_LENGTHS = [10, 20, 50, 100]

        # ORDER_MAPPINGS
        #
        # Should be redefined by the subclass.  Should be a Hash with String keys,
        # where the key represents the parameter name used in the URL and the
        # value represents the column name.
        #
        # If the parameter is an array, the first entry should be the column name, and the
        # second(and last) entry should be a unique column that can be used as a secondary
        # ordering.  NOTE: if the column is not unique, it is important that this secondary
        # order by provided, else pagination may be inconsistent.
        #
        # Example:
        #
        # {
        #   'name' => ['<table_name>.name', :id],
        #   'created' => '<table_name>.created_at'
        # }
        #
        # ORDER_MAPPINGS = {}

        # DEFAULT_ORDER
        #
        # Should be defined by any implementing controller that also defines ORDER_MAPPINGS.
        # Provides the default column for ordering, as well as the default direction.
        #
        # Must be of type Array and length 1 or 2.  Position 0 contains the default column.  Its
        # value MUST match that of the key value of the column inside the ORDER_MAPPINGS Hash.
        #
        # If provided, position 1 should contain 'asc' or 'desc', indicating the default
        # direction.
        #
        # Example:
        #
        # ['name', 'asc']
        #
        # DEFAULT_ORDER = {}

        # list/search page for model_class
        def index
          @page_class = 'change-list'

          # handle pagination length parameter passed by the browser
          if new_length = self.class::PAGINATION_LENGTHS.detect{|l| l == params[:per_page].to_i}
            session[:records_per_page] = new_length
          else
            session[:records_per_page] ||= self.class::ADMIN_LIST_PAGINATION_LENGTH
          end
          @records_per_page = session[:records_per_page] || self.class::ADMIN_LIST_PAGINATION_LENGTH

          page = (params[:page] ||= 1).to_i

          filter_conditions, search_conditions, conditions = nil

          filter_conditions = build_filter_conditions
          search_conditions = build_search_conditions(params[:q])

          if params[:search_id].to_s.match(/^\d+$/) && model_class.find_by_id(params[:search_id].to_i)
            final_conditions = ["#{model_class.table_name}.id = ?", params[:search_id].to_i]
          else
            all_conditions = [filter_conditions, search_conditions].map do |conds|
              if conds.is_a?(Array)
                conds
              elsif conds.is_a?(String)
                [conds]
              else
                nil
              end
            end.compact

            final_conditions = []
            if all_conditions.length > 0
              final_conditions = [all_conditions.map { |conds| "(#{conds.shift})" }.join(" AND ")]
              all_conditions.each { |conds| final_conditions += conds }
            end
          end
          final_conditions = nil if final_conditions.length == 0

          scope_method = model_class.method(model_scope_name)
          if params[:export] == 't' && self.class.can_export_csv?
            self.models = scope_method.call.find(:all, :conditions => final_conditions, :order => build_order_string)

            # subclass versions of #index may define @csv_headings as a Hash and/or @csv_columns as an array, prior to
            # calling the super#index.  These manipulate the columns and headings of the output.
            render_csv_from_result_set(models, :headings => @csv_headings, :columns => @csv_columns)
          else
            if params[:no_paging] == 't' && self.class.can_disable_pagination?
              self.models = scope_method.call.find(:all, :conditions => final_conditions, :order => build_order_string)
            else
              self.models = scope_method.call.paginate(:conditions => final_conditions, :page => page, :per_page => @records_per_page, :order => build_order_string)
            end

            session[:last_admin_index] = request.request_uri
            @last_visited = session[:last_admin_edited]
            session[:last_admin_edited] = nil
          end
        end

        # add page for model_class
        def add
          @page_class = 'change-form'

          @redirect_called = false
          yield :find_associated, nil
          return if @redirect_called

          self.model = model_class.new(params[model_symbol])

          return unless request.post?

          begin
            yield :before_save, model
            model.save!
            yield :after_save, model

            send(self.class.config_options[:audit_trail], model, 'create') if self.class.config_options[:audit_trail]
            yield :success, model
            redirect_based_on_submit_value(model.id)
          rescue ActiveRecord::RecordInvalid
            # errors found - rerender to display errors
            return
          end
        end

        def edit
          @page_class = 'change-form'

          @redirect_called = false
          yield :find_associated, nil
          return if @redirect_called

          begin
            yield :before_find, nil
            self.model = model_class.find(params[:id])
            yield :after_find, model
          rescue ActiveRecord::RecordNotFound
            # could not find the record - yield :not_found should do some form of redirect
            flash[:notice] = {:error => "Record does not exist.  Could not edit #{humanized_model_name} with ID: #{params[:id]}"}
            yield :not_found, nil
          end

          return unless request.post?

          begin
            yield :before_update, model
            model.update_attributes!(params[model_symbol])

            send(self.class.config_options[:audit_trail], model, 'edit') if self.class.config_options[:audit_trail]
            yield :success, model

            redirect_based_on_submit_value(model.id)
          rescue ActiveRecord::RecordInvalid
            # errors found - rerender to display errors
            return
          end
        end

        def move
          direction = ['up', 'down'].detect {|dir| dir == params[:direction]}

          # move the record and redisplay index
          if direction
            # find simple text and remove it
            object = model_class.find(params[:id])

            object.move(direction)

            remember_last_visited_record(object)
          end

          redirect_to_last_index_or_back
        end


        private

          # store_location
          #
          # Stores the current request_uri in the session.  For use with redirect_back_or_default
          # which returns the user to the last viewed page.
          #
          # Exceptions to this rule should be handled by using skip_after_filter where
          # possible.  Else put logic in this method.
          #
          def store_location
            # dont store if we are exporting a file
            return true if response.sending_file?

            session[:return_to] = request.request_uri
            return true
          end

          # redirect_back_or_default
          #
          # Tied in with store_location.  This redirects to the page stored in session[:return_to]
          # if available, else redirects to <default>.
          #
          def redirect_back_or_default(default)
            redirect_to(session[:return_to] || default)
            session[:return_to] = nil
          end

          # redirect_based_on_submit_value
          #
          # This method should be overloaded to provide a more comprehensive switch
          # for different redirects, based on different submit values.
          #
          # redirect_urls MUST be implemented in your controller to support the actual
          # url generation for the redirect.
          #
          def redirect_based_on_submit_value(object_id = nil)
            if params[:_continue]
              redirect_to(redirect_urls(:edit, object_id))
            # Here's another suggested option that might be wanted for a particular
            # controller.  Overload this method to add this functionality
#            elsif params[:_another]
#              redirect_to(redirect_urls(:add))
            else # this means params[:_save]
              redirect_to(redirect_urls(:index))
            end
          end

          # build_order_string
          # Should be no need to override this method in subclass controller.  This
          # method assumes that the subclassed controller has defined
          # self.order_mappings, else completely inappropriate defaults may be used.
          #
          # returns a valid SQL string in formate "<table_name>.<column_name> <direction>"
          #
          #
          def build_order_string
            # no order mappings supplied - no ordering
            return nil unless self.class.constants.include?('ORDER_MAPPINGS') && self.class::ORDER_MAPPINGS.length > 0

            unless order = self.class::ORDER_MAPPINGS[params[:order]]
              params[:order] = self.class.constants.include?('DEFAULT_ORDER') ?
                self.class::DEFAULT_ORDER[0] :
                self.class::ORDER_MAPPINGS.keys.first
              order = self.class::ORDER_MAPPINGS[params[:order]]
            end

            # no order mapping matched request - no ordering
            return nil unless order

            unless ['asc', 'desc'].include?(params[:direction].to_s.downcase) && direction = params[:direction].to_s.downcase
              params[:direction] = direction = self.class.constants.include?('DEFAULT_ORDER') ? self.class::DEFAULT_ORDER[1] : 'asc'
            end

            if order.is_a?(Array)
              return [[order.first, direction].join(' '), ["#{model_class.table_name}.#{order.last.to_s}", direction].join(' ')].join(', ')
            else
              return [order, direction].join(' ')
            end
          end

          # build_search_conditions
          # Need only be defined if there is a search interface.  If it is defined
          # it MUST be formatted as:
          #
          # ["<you_conditions_here>", param1, params2, ....]
          #
          def build_search_conditions(query)
            return nil
          end

          # build_filter_conditions
          # Need only be defined if there are filters on the index.  If it is defined
          # it MUST be formatted as:
          #
          # ["<you_conditions_here>", param1, params2, ....]
          #
          def build_filter_conditions
            return nil
          end

          # load_many_to_many_from_record_select
          #
          # Load associated records of Class <klass> from standard @params structure
          # used by the record_select plugin.  These are stored in the attribute
          # named <name>.
          #
          # Returns an array of <klass> objects
          #
          def load_many_to_many_from_record_select(name, klass)
            return [] unless params[name.to_sym].is_a?(Array)

            assoc_ids = []
            associations = []
            params[name.to_sym].each do |id|
              begin
                associations << klass.find(id) unless assoc_ids.include?(id)
                assoc_ids << id
              end
            end

            return associations
          end

          # load_belongs_to_from_record_select
          #
          # Load associated belongs_to record of Class <klass> from standard @params
          # structure used by the record_select plugin.  These are stored in the
          # attribute named <name>.
          #
          # Returns nil or an object of Class <klass>.
          #
          def load_belongs_to_from_record_select(name, klass)
            return nil if params[name.to_sym].nil?

            parent_ob = nil

            begin
              parent_ob = klass.find(params[name.to_sym].to_s)
            rescue ActiveRecord::RecordNotFound
              # do nothing - parent_object already nil
            end

            return parent_ob
          end

      end

    end
  end
end
