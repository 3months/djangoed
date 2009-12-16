module ActionController
  module Extensions
    module RecordSelect

      module InstanceMethods
        
        # record_select_conditions_from_search
        #
        # This method is defined by the record_select plugin that is used by djangoed
        # and is overloaded here.
        # It has a bug where by it downcases all search text by then performs a LIKE
        # query.  We need to change this to also downcase the queried column.
        #
        def record_select_conditions_from_search
          search_pattern = record_select_config.full_text_search? ? '%?%' : '?%'

          if params[:search] and !params[:search].strip.empty?
            tokens = params[:search].strip.split(' ')

            where_clauses = record_select_config.search_on.collect { |sql| "lower(#{sql}) LIKE ?" }
            phrase = "(#{where_clauses.join(' OR ')})"

            sql = ([phrase] * tokens.length).join(' AND ')
            tokens = tokens.collect{ |value| [search_pattern.sub('?', value.downcase)] * record_select_config.search_on.length }.flatten

            return [sql, *tokens]
          end
        end

      end
      
    end
  end
end
