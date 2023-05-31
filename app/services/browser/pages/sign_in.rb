require './spec/helpers/browser/pages/page'

module Browser
  module Pages
    class SignIn < Page
      def username_text_field
        element(@browser.text_field(name: 'username'))
      end

      def password_input
        element(@browser.input(name: 'password'))
      end

      def login_button
        element(@browser.button(id: 'submitbuttonlogin_form'))
      end
    end
  end
end
