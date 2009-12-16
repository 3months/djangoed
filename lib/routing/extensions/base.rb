module Routing
  module Extensions
    module Base

      DJANGOED_CORE_DEFAULT_ACTIONS = {
        'index' => {:url_method => "?_index", :url => "?"},
        'add' => {:url_method => "?_add", :url => "?/add"},
        'edit' => {:url_method => "?_edit", :url => "?/edit/:id"}
      }
      DJANGOED_EXT_DEFAULT_ACTIONS = {
        'move' => {:url_method => "?_move", :url => "?/move/:id/:direction", :conditions => {:method => :post}}
      }

      def djangoed_routes_for_controller(controller, content, options = {}, &block)
        actions = options.delete(:actions) || :core
        if actions == :core
          route_actions = DJANGOED_CORE_DEFAULT_ACTIONS
        elsif actions == :all
          route_actions = all_djangoed_default_actions
        else
          if actions.is_a?(Hash)
            route_actions = {}
            actions.each do |aktion, opt_hash|
              key = aktion.to_s.downcase
              route_actions[key] = all_djangoed_default_actions[key].merge(opt_hash)
            end
          elsif actions.is_a?(Array)
            route_actions = {}
            actions.each do |aktion|
              key = aktion.to_s.downcase
              route_actions[key] = all_djangoed_default_actions[key]
            end
          else # actions must be an a single key
            route_actions = {}
            [actions].each do |aktion|
              key = aktion.to_s.downcase
              route_actions[key] = all_djangoed_default_actions[key]
            end
          end
        end

        with_options(:controller => controller) do |obj|
          if route_actions.keys.include?('index')
            obj.send(route_actions['index'][:url_method].gsub(/\?/, content), route_actions['index'][:url].gsub(/\?/, content), :action => 'index')
          end
          if route_actions.keys.include?('add')
            obj.send(route_actions['add'][:url_method].gsub(/\?/, content), route_actions['add'][:url].gsub(/\?/, content), :action => 'add')
          end
          if route_actions.keys.include?('edit')
            obj.send(route_actions['edit'][:url_method].gsub(/\?/, content), route_actions['edit'][:url].gsub(/\?/, content), :action => 'edit')
          end
          if route_actions.keys.include?('move')
            obj.send(route_actions['move'][:url_method].gsub(/\?/, content), route_actions['move'][:url].gsub(/\?/, content), :action => 'move')
          end

          block.call(obj) if block
        end
      end

      private

        def all_djangoed_default_actions
          return DJANGOED_CORE_DEFAULT_ACTIONS.merge(DJANGOED_EXT_DEFAULT_ACTIONS)
        end

    end
  end
end