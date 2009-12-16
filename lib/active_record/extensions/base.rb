module ActiveRecord
  module Extensions
    module Base

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        def djangoed_content(options = {})
          include ActiveRecord::Extensions::ManagedContent::InstanceMethods
          extend ActiveRecord::Extensions::ManagedContent::ClassMethods

          if options[:tree]
            include ActiveRecord::Extensions::Tree::InstanceMethods
            # extend ActiveRecord::Extensions::Enumerable::ClassMethods
          end
        end

        def enumerable_methods
          include ActiveRecord::Extensions::Enumerable::InstanceMethods
          extend ActiveRecord::Extensions::Enumerable::ClassMethods
          before_save :validate_enumerables
        end

        def sluggable(options = {})
          cattr_accessor :slug_read_method, :slug_write_method, :title_method
          self.slug_read_method = options[:slug_read_method] ? options[:slug_read_method].to_sym : :slug
          self.slug_write_method = options[:slug_write_method] ? slug_read_method.to_s + '=' : :slug=
          self.title_method = options[:title_method] ? options[:title_method].to_sym : :title


          include ActiveRecord::Extensions::Sluggable::InstanceMethods
          # extend ActiveRecord::Extensions::Sluggable::ClassMethods

          if options[:callback].is_a?(Symbol)
            send(options[:callback], :generate_slug)
          elsif options[:callback] != false
            before_save :generate_slug
          end
        end
      end
      
    end
  end
end

ActiveRecord::Base.send(:include, ActiveRecord::Extensions::Base)

