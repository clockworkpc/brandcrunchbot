require 'rails_helper'

RSpec.describe AllmoxyApiBeta::CompanyService do
  let(:companies_json) { JSON.parse(File.read('spec/fixtures/allmoxy_api_beta/companies.json')) }

  before(:all) do
    @service = described_class.new
  end

  describe 'GET Requests' do
    it 'gets all companies', focus: true do
      res = @service.companies
      expect(res).to eq(companies_json)
      expect(res['entries']).not_to be_empty
    end

    it 'gets company WHERE company_id=0', focus: true do
      res, entry = test_entry(company_id: 1)
      expect(res).to eq(entry)
    end

    it 'gets company WHERE company_id=1', focus: true do
      res, entry = test_entry(company_id: 2)
      expect(res).to eq(entry)
    end

    it 'gets company WHERE company_id=2', focus: true do
      res, entry = test_entry(company_id: 3)
      expect(res).to eq(entry)
    end
  end

  def find_entry(company_id)
    companies_json['entries'].find { |e| e['company_id'] == company_id }
  end

  def test_entry(company_id:)
    res = @service.companies(company_id:)
    entry = find_entry(company_id)
    [res, entry]
  end
end
