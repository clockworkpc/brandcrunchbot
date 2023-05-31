require './spec/helpers/browser/pages/page'

module Browser
  module Pages
    class Home < Page
      ## Top Right Avatar
      def avatar_image
        element(@browser.svg(class: 'fright'))
      end

      def login_info_dropdown
        element(@browser.div(id: 'login_info').ul)
      end

      def find_dropdown_li(str)
        login_info_dropdown.children.find { |li| li.a.href.match?(str) }
      end

      def home_link
        find_dropdown_li('home')
      end

      def account_info_link
        find_dropdown_li('edit')
      end

      def new_note_link
        find_dropdown_li('notes')
      end

      def new_task_link
        find_dropdown_li('tasks_new')
      end

      def new_announcements_link
        find_dropdown_li('announcements')
      end

      def time_tracking_link
        find_dropdown_li('time_tracking')
      end

      def modals_scanner_link
        find_dropdown_li('modals')
      end

      def timecard_scanner_link
        find_dropdown_li('timecard')
      end

      def logout_link
        find_dropdown_li('logout')
      end

      ## Navigation Bar
    end
  end
end
