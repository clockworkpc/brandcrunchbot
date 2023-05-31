module Browser
  class BrowserMissingError < StandardError; end

  class Page
    def initialize(browser)
      raise BrowserMissingError if browser.nil?

      @browser = browser
    end

    def element(el)
      el.wait_until(&:present?)
    end

    # def home_div(username)
    #   element(@browser.div(visible_text: username))
    # end

    # def sign_out_link
    #   element(@browser.link(href: '/users/sign_out'))
    # end

    # def projects_link
    #   element(@browser.link(href: '/home/projects'))
    # end

    # def organisations_link
    #   element(@browser.link(href: '/home/organisations'))
    # end
  end
end
