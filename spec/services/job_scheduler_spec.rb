require 'rails_helper'

RSpec.describe JobScheduler do
  let(:domain_range) { 'domains_test!A1:C' }
  let(:report_range) { 'reports_test!A1:E' }

  before(:all) do
    @service = described_class.new
  end

  describe 'Buy It Now' do
    it 'retrieves domains from Google Sheet' do
      res = @service.retrieve_domains_from_google_sheet(domain_range:)
      pp res
    end
  end
end
