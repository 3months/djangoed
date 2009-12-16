module ActiveRecord
  module Extensions
    module Tree

#      module ClassMethods
#
#      end

      module InstanceMethods

        def move(direction)
          return false unless [:down, :up].include?(direction.intern)
          return false unless self.position.is_a?(Fixnum)

          if direction.intern == :down
            sibling = find_sibling_below
            return false unless sibling
          else
            sibling = find_sibling_above
            return false unless sibling
          end

          their_position = sibling.position

          sibling.position = self.position
          sibling.save(false)

          self.position = their_position
          save(false)

          return true
        end

        private

          def find_sibling_below
            if self.parent.nil?
              return self.class.find(:first, :conditions => ["position > ? AND parent_id IS NULL", self.position.to_i], :order => 'position ASC')
            else
              return self.class.find(:first, :conditions => ["position > ? AND parent_id = ?", self.position.to_i, self.parent.id], :order => 'position ASC')
            end
          end

          def find_sibling_above
            if self.parent.nil?
              return self.class.find(:first, :conditions => ["position < ? AND parent_id IS NULL", self.position.to_i], :order => 'position DESC')
            else
              return self.class.find(:first, :conditions => ["position < ? AND parent_id = ?", self.position.to_i, self.parent.id], :order => 'position DESC')
            end
          end

      end

    end
  end
end