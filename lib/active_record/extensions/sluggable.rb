module ActiveRecord
  module Extensions
    module Sluggable

      # module ClassMethods
      # 
      # end

      module InstanceMethods

        def get_slug
          return self.send(self.class.slug_read_method)
        end

        private

        def generate_slug
          read_slug = method(self.class.slug_read_method)
          write_slug = method(self.class.slug_write_method)
          # Dont update slug (may be bookmarked etc)
          if read_slug.call && read_slug.call.to_s.length >= 4
            write_slug.call(strip_non_slug_characters(read_slug.call))
            return true
          end

          temp_title = send(self.class.title_method)
          write_slug.call(temp_title.to_s.mb_chars.downcase.strip)

          write_slug.call(strip_non_slug_characters(read_slug.call).to_s)

          while read_slug.call.length < 4
            write_slug.call(read_slug.call + '0')
          end

          # now limit the length of the slug
          # note that is is limiting to 252 to allow for the random 3 characters that are added when duplicates are found
          write_slug.call(read_slug.call[0...252])
          while test_for_existing_slug(read_slug.call)
            write_slug.call(read_slug.call + '-' + Digest::SHA1.hexdigest("--#{Time.now.to_s}--")[0..2])
            write_slug.call(read_slug.call[0...252])
          end

          return true
        end

        def strip_non_slug_characters(string)
          # convert whitespace to '-'
          temp_string = string.to_s.mb_chars.gsub(/\s+/, '-')
          # strip illegal characters
          temp_string = temp_string.to_s.mb_chars.gsub(/[^a-z0-9\-]+/i, '')
          # finally remove repetitions of '-'
          temp_string = temp_string.to_s.mb_chars.gsub(/-{2,}/, '-')

          return temp_string
        end

        def test_for_existing_slug(slug)
          return self.class.find(:first, :conditions => ["#{self.class.table_name}.#{self.class.slug_read_method.to_s} = ?", slug])
        end

      end

    end
  end
end
