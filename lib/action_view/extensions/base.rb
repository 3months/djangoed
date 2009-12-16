module ActionView
  module Extensions
    module Base

      include ActionView::Extensions::Filters
      include ActionView::Extensions::RecordSelect

      def display_move_arrows(siblings, sibling, i, move_url_method)
        show_up, show_down = i > 0, i < (siblings.length - 1)
        arrows = []

        arrows << link_to(image_tag('/images/admin/arrow-up.gif', :alt => 'Up'), move_url_method.call(:direction => 'up', :id => sibling.id), :method => :post) if show_up
        arrows << link_to(image_tag('/images/admin/arrow-down.gif', :alt => 'Down'), move_url_method.call(:direction => 'down', :id => sibling.id), :method => :post) if show_down
        return arrows.join('&nbsp;')
      end

      def admin_right_col_filter_listing(name, options, null_option = false)
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

      def filter_selection_box(name, collection, options = {})
        return select_tag(name, options_for_select(collection, params[name]), options)
      end

      # admin_table_heading
      #
      # Produces a <th> tag for heading a sortable column.  <name> is the value displayed
      # in the tag, <order_name> is value passed in the order attribute of the query
      # string.
      #
      # <html_options> are passed to the <th> tag.
      #
      def admin_table_heading(name, order_name, html_options = {})
        class_names = []
        if order_name == params[:order]
          class_names << 'sorted'
          class_names << (params[:direction].downcase == 'desc' ? 'descending' : 'ascending')

          new_order = (params[:direction].downcase == 'desc' ? 'asc' : 'desc')
        else
          new_order = 'asc'
        end
        class_names << html_options[:class]
        class_names.compact!
        html_options[:class] = class_names.length > 0 ? class_names.join(' ') : nil

        return content_tag(:th, content_tag(:a, name, :href => url_for(params.merge(:order => order_name, :direction => new_order))), html_options)
      end

      ##############################################################################
      ### Pagination view helpers for the admin interface
      #

      # display_paginator
      #
      # Renders a content tag containing standard windowed pagination links, using pagination_links().
      # Then displays the total count of the items.
      #
      # <collection> is either a WillPaginator::Collection or an Array.
      # <options> are currently:
      #   => :object_name - for display as 'X objects'.  Defaults to 'item'
      #   => :tag - html tag to be used to wrap pagination section
      #   => :no_per_page - do not render the per_page links in the pagination block
      #   => :per_page_lengths - the values that are available for selecting
      #       pagination length
      # <html_options> are passed to the content_tag
      #
      def display_paginator(collection, options = {}, html_options = {})
        object_name = options[:object_name] || 'item'
        length = collection.is_a?(WillPaginate::Collection) ? collection.total_entries : collection.length
        per_page = collection.is_a?(WillPaginate::Collection) && !options[:no_per_page] ? collection.per_page : nil
        tag = options[:tag] || :p
        lengths = options[:per_page_lengths] || controller.class::PAGINATION_LENGTHS

        return content_tag(tag, html_options) do
          parts = [
            pagination_links(collection),
            length,
            length == 1 ? object_name : object_name.pluralize
          ]
          if per_page
            parts += [
              '| per page:',
              lengths.map {|l| change_pagination_length_link(per_page, l)}.join(', ')
            ]
          end
          parts.join(' ')
        end
      end

      def change_pagination_length_link(current, destination)
        return destination.to_s if destination == current

        return link_to(destination.to_s, params.merge(:per_page => destination))
      end

      # pagination links
      #
      # Window based pagination system where we show pages near the current page, and the
      # ends of the collection, with ... in between
      #
      def pagination_links(collection)
        # We now can disable pagination, so we check to make sure it is on before rendering this
        return nil unless collection.is_a?(WillPaginate::Collection)
        links = []
        lower_window, upper_window = window_limits(collection, 5)

        if lower_window == 2
          lower_window = 1
        end
        if upper_window == (collection.total_pages - 1)
          upper_window = collection.total_pages
        end

        if lower_window > 1
          (1..2).each do |i|
            links << pagination_link(collection, i)
          end
          links << '...'
        end
        (lower_window..upper_window).each do |i|
          links << pagination_link(collection, i)
        end
        if upper_window < collection.total_pages
          links << '...'
          ((collection.total_pages - 1)..collection.total_pages).each do |i|
            links << pagination_link(collection, i)
          end
        end

        return links.join(' ')
      end

      def window_limits(collection, window_size)
        lower = [collection.current_page - (window_size / 2), 1].max
        upper = [collection.current_page + (window_size / 2), collection.total_pages].min

        if lower == 1
          upper = [lower + (window_size - 1), collection.total_pages].min
        end
        if upper == collection.total_pages
          lower = [upper - (window_size - 1), 1].max
        end

        return [lower, upper]
      end

      def pagination_link(collection, page)
        if collection.current_page == page
          return content_tag(:span, page, :class => 'this-page')
        else
          return link_to(page, params.merge(:page => page), :class => 'page')
        end
      end
      #
      ### End pagination view helpers for admin interface
      ##############################################################################

    end
  end
end
