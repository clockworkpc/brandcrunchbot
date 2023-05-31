require 'rails_helper'

RSpec.describe BrowserService::AllmoxyCustomerService do
  let(:spreadsheet_id) { Rails.application.credentials[:spreadsheet_id_allmoxy_customers_dev] }

  before(:all) do
    @browser = Utils.watir_browser(headless: false)
  end

  after(:all) do
    @browser.close
  end

  it 'downloads companies', focus: false do
    service = described_class.new(@browser)
    service.download_companies
    sleep 2
    expect(Utils.latest_csv_in_tmp).to match('companies')
  end

  it 'downloads people', focus: false do
    service = described_class.new(@browser)
    service.download_people
    sleep 2
    expect(Utils.latest_csv_in_tmp).to match('people')
  end

  describe 'uploads' do
    before do
      @gsa = GoogleSheetsApi.new
    end

    it 'uploads_companies', focus: false do
      @gsa.here_be_dragons(spreadsheet_id:, range: 'companies_auto_update!A1:BZ')
      service = described_class.new(@browser)
      csv_path = Utils.latest_csv_in_tmp(str: 'companies')
      service.upload_customers(spreadsheet_id:, csv_path:, type: :companies)
    end

    it 'uploads_people', focus: false do
      @gsa.here_be_dragons(spreadsheet_id:, range: 'people_auto_update!A1:BZ')
      service = described_class.new(@browser)
      csv_path = Utils.latest_csv_in_tmp(str: 'people')
      service.upload_customers(spreadsheet_id:, csv_path:, type: :people)
    end

    it 'refreshes companies_auto_update', focus: true do
      @gsa.here_be_dragons(spreadsheet_id:, range: 'companies_auto_update!A1:BZ')
      @gsa.here_be_dragons(spreadsheet_id:, range: 'people_auto_update!A1:BZ')
      csv_0 = Utils.latest_csv_in_tmp(str: 'companies')
      service = described_class.new(@browser)
      service.refresh_customers(spreadsheet_id:)
      csv_path = Utils.latest_csv_in_tmp(str: 'companies')
      expect(csv_path).not_to eq(csv_0)
    end
  end
end
