require 'rails_helper'

RSpec.describe BrowserService::AllmoxyProductService do
  let(:product_id) { 660 }
  let(:part_id) { 116_249 }
  let(:export_formula) { 'hello world' }

  before :all do
    @browser = Watir::Browser.new(:chrome, headless: false)
    @service = described_class.new(@browser, false)
  end

  # it 'updates the Applied Molding export formula', focus: true do
  #   res = @service.update_part_export_formula(product_id:, part_id:, formula: export_formula)
  # end
end
