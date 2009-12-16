module ActionView
  module Extensions
    module RecordSelect

      # label_for_field
      #
      # This method is defined by the record_select plugin that is used by djangoed
      # and is overloaded here.
      # It has a bug where by #render_record_from_config only accepts 1 or 2 args,
      # not 3 as in their version.
      #
      def label_for_field(record, controller = self.controller)
        renderer = controller.record_select_config.label
        case renderer
        when Symbol, String
          # find the <label> element and grab its innerHTML
          description = render_record_from_config(record, File.join(controller.controller_path, renderer.to_s))
          description.match(/<label[^>]*>(.*)<\/label>/)[1]

        when Proc
          # just return the string
          render_record_from_config(record, renderer)
        end
      end

    end
  end
end