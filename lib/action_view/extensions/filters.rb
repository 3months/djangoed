module ActionView
  module Extensions
    module Filters

      # filter_form_javascript
      #
      # Render javascript snippet that will submit the filter form whenever the select
      # boxes are changed. <form_id> is the form that will be submitted and
      # <container_desc> is the prototype style element description of a container
      # that will contain all the select boxes.
      #
      def filter_form_javascript(form_id = 'changelist-search', container_desc = 'span.right-filters')
        javascript_tag do
"$$('#{container_desc} select').each(function(s) {
  s.observe('change', function(e) {
    $('#{form_id}').submit();
  });
});"
        end
      end

      def filter_listing(name, options, null_option = false)
        if name.is_a?(Array)
          url_name, name = name.first, name.last
        else
          url_name = name
        end
        li_options = [content_tag(:li, link_to('All', params.merge(url_name.to_sym => nil, "no_#{url_name}".to_sym => nil, :page => nil, :order => nil, :direction => nil, :search_id => nil)), :class => (params[url_name.to_sym].nil? && params["no_#{url_name}".to_sym].nil? ? 'selected' : nil))]

        if options.is_a?(Hash)
          options.each do |key, value|
            if key.to_s == params[url_name.to_sym]
              li_options << content_tag(:li, link_to(value.capitalize, params.merge(url_name.to_sym => key, "no_#{url_name}".to_sym => nil, :page => nil, :order => nil, :direction => nil, :search_id => nil)), :class => 'selected')
            else
              li_options << content_tag(:li, link_to(value.capitalize, params.merge(url_name.to_sym => key, "no_#{url_name}".to_sym => nil, :page => nil, :order => nil, :direction => nil, :search_id => nil)))
            end
          end
        else
          options.each do |option|
            if option.send(name.to_sym) == params[url_name.to_sym]
              li_options << content_tag(:li, link_to(option.send(name.to_sym).capitalize, params.merge(url_name.to_sym => option.send(name.to_sym), "no_#{url_name}".to_sym => nil, :page => nil, :order => nil, :direction => nil, :search_id => nil)), :class => 'selected')
            else
              li_options << content_tag(:li, link_to(option.send(name.to_sym).capitalize, params.merge(url_name.to_sym => option.send(name.to_sym), "no_#{url_name}".to_sym => nil, :page => nil, :order => nil, :direction => nil, :search_id => nil)))
            end
          end
        end

        if null_option
          li_options << content_tag(:li, link_to('None', params.merge("no_#{url_name}".to_sym => 'true', url_name.to_sym => nil, :page => nil, :order => nil, :direction => nil, :search_id => nil)), :class => (params["no_#{url_name}".to_sym].nil? ? nil : 'selected'))
        end

        return li_options
      end

      def relationship_filter_listing(name, name_field, search_field, options)
        li_options = [content_tag(:li, link_to('All', params.merge(name.to_sym => nil, :page => nil, :order => nil, :direction => nil, :search_id => nil)), :class => (params[name.to_sym].nil? ? 'selected' : nil))]

        options.each do |option|
          next unless option.respond_to?(name_field) && option.respond_to?(search_field)

          if option.send(search_field.to_sym).to_s == params[name.to_sym]
            li_options << content_tag(:li, link_to(option.send(name_field.to_sym).capitalize, params.merge(name.to_sym => option.send(search_field.to_sym), :page => nil, :order => nil, :direction => nil, :search_id => nil)), :class => 'selected')
          else
            li_options << content_tag(:li, link_to(option.send(name_field.to_sym).capitalize, params.merge(name.to_sym => option.send(search_field.to_sym), :page => nil, :order => nil, :direction => nil, :search_id => nil)))
          end
        end

        return li_options
      end

      def boolean_filter_listing(name, keys = nil)
        true_key = name.capitalize
        false_key = "Not #{name.capitalize}"
        if keys.is_a?(Hash)
          true_key = keys[:true] unless keys[:true].nil?
          false_key = keys[:false] unless keys[:false].nil?
        end

        return [
          content_tag(:li, link_to('All', params.merge(name.to_sym => nil, :page => nil, :order => nil, :direction => nil, :search_id => nil)), :class => (params[name.to_sym].nil? ? 'selected' : nil)),
          content_tag(:li, link_to(true_key, params.merge(name.to_sym => 'true', :page => nil, :order => nil, :direction => nil, :search_id => nil)), :class => (params[name.to_sym] == 'true' ? 'selected' : nil)),
          content_tag(:li, link_to(false_key, params.merge(name.to_sym => 'false', :page => nil, :order => nil, :direction => nil, :search_id => nil)), :class => (params[name.to_sym] == 'false' ? 'selected' : nil))
        ]
      end

      def filter_selection_box(name, collection, options = {})
        return select_tag(name, options_for_select(collection, params[name]), options)
      end

    end
  end
end
