require 'rails_helper'

RSpec.describe AllmoxyConfigService do
  let(:company_csv_path) { 'config/allmoxy/allmoxy_companies.csv' }
  let(:individual_csv_path) { 'config/allmoxy/allmoxy_individuals.csv' }

  before(:all) { @service = described_class.new }

  it 'extracts companies from CSV', focus: false do
    @service.import_companies_from_csv(company_csv_path)
  end

  it 'extracts individuals from CSV', focus: true do
    @service.import_individuals_from_csv(individual_csv_path)
  end

  it 'extracts companies and individuals', focus: true do
    @service.import_companies_from_csv(company_csv_path)
    @service.import_individuals_from_csv(individual_csv_path)
  end
end
