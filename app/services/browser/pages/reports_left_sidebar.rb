require './spec/helpers/browser/pages/page'

module Browser
  module Pages
    class ReportsLeftSidebar < Page
      def start_date_picker
        element(@browser.input(id: 'rep_start_date'))
      end

      def end_date_picker
        element(@browser.input(id: 'rep_end_date'))
      end

      def date_picker_current_date(type:)
        DateTime.parse(send("#{type}_date_picker").attributes[:value])
      end

      def date_picker_current_month(type:)
        date_picker_current_date(type:).month
      end

      def date_picker_current_day(type:)
        date_picker_current_date(type:).day
      end

      def date_picker_buttons
        element(@browser.inputs(class: 'dpButton'))
      end

      def date_picker_button_this_month_last_year
        date_picker_buttons[0]
      end

      def date_picker_button_month_back
        date_picker_buttons[1]
      end

      def date_picker_button_forward
        date_picker_buttons[2]
      end

      def date_picker_button_this_month_next_year
        date_picker_buttons[3]
      end

      def refresh_date_picker_onclick_text(date:, year:, month:)
        [
          "return refreshDatePicker(\"#{date}_date_\"",
          'false',
          "#{year}, #{month});"
        ].join(', ')
      end

      def update_date_field_onclick_text(date:, year:, month:, day:)
        octal = ->(int) { format('%02d', int) }
        "return updateDateField('#{date}_date_', '#{year}-#{octal.call(month)}-#{octal.call(day)}',false);"
      end

      def month_input(date:, year:, month:)
        element(@browser.input(onclick: refresh_date_picker_onclick_text(date:, year:, month:)))
      end

      def date_picker_day_td(date:, year:, month:, day:)
        element(@browser.td(onclick: update_date_field_onclick_text(date:, year:, month:, day:)))
      end

      def submit_button
        element(@browser.button(type: 'submit', onclick: 'return MoxForm.Go(this);'))
      end

      # def date_picker_current_date(date:)
      #   start_date_picker.click
      # end
    end
  end
end
