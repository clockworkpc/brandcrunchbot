class BrowserService
  class AllmoxyCustomerService < AllmoxyService
    BASE_URL = 'https://panhandledooranddrawer.allmoxy.com'.freeze
    COMPANIES_URL = [BASE_URL, 'accounts', 'companies', '#role=Customers|status=1'].join('/').freeze
    PEOPLE_URL = [BASE_URL, 'accounts', 'people'].join('/').freeze

    def download_customers(type:)
      url = "BrowserService::AllmoxyCustomerService::#{type.upcase}_URL".constantize
      onclick = "return export_from_livetable('#{type}');"

      @browser.goto(url)
      sidebar = @browser.div(id: 'sidebar_content')
      send_to_h2 = sidebar.h2s.first
      send_to_h2.focus
      send_to_h2.click
      export_to_csv_link = @browser.a(onclick:)
      export_to_csv_link.focus
      export_to_csv_link.click
      sleep 3
    end

    def download_companies
      download_customers(type: :companies)
    end

    def download_people
      download_customers(type: :people)
    end

    def upload_customers(spreadsheet_id:, csv_path:, type:)
      range = "#{type}_auto_update!A1:BZ"

      gsa = GoogleSheetsApi.new
      Rails.logger.info("Clearing values from #{spreadsheet_id}, #{range}".light_cyan)
      gsa.clear_values(spreadsheet_id:, range:)
      Rails.logger.info("Updating values in #{spreadsheet_id}, #{range}".light_cyan)
      res = gsa.update_values(spreadsheet_id:, range:, csv_path:)
      Rails.logger.info('Values updated!'.light_cyan)
      res
    end

    def upload_companies(spreadsheet_id:)
      csv_path = Utils.latest_csv_in_tmp(str: 'companies')
      upload_customers(spreadsheet_id:, csv_path:, type: :companies)
    end

    def upload_people(spreadsheet_id:)
      csv_path = Utils.latest_csv_in_tmp(str: 'people')
      upload_customers(spreadsheet_id:, csv_path:, type: :people)
    end

    def refresh_customers(spreadsheet_id:)
      download_companies
      download_people
      upload_companies(spreadsheet_id:)
      upload_people(spreadsheet_id:)
    end
  end
end
