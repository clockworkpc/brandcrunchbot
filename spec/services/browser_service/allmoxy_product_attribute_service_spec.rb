# require 'rails_helper'

# RSpec.describe BrowserService::AllmoxyProductAttributeService do
#   let(:product_attribute_ids) { [379, 380] }

#   before(:all) do
#     @browser = Watir::Browser.new
#     @service = described_class.new(@browser, true)
#   end

#   describe 'product attribute backup' do
#     # it 'backs up a product attribute as a line item in a Google sheet' do
#     #   product_attribute_id = 379
#     #   hsh = @service.product_attribute_hash(product_attribute_id:)
#     #   # list expectations
#     # end

#     # it 'backs up product attribute selection options', focus: false do
#     #   product_attribute_id = 379
#     #   csv_path = @service.back_up_product_attribute_selections(product_attribute_id:)
#     # end

#     # it 'backs up product_attributes and selection options', focus: false do
#     #   ary = @service.back_up_product_attributes(product_attribute_ids:)
#     # end

#     it 'backs up main details for each product attribute details as a line item in a Google Sheet', focus: true do
#       @service.back_up_product_attribute_details(product_attribute_ids: [11, 45, 101])
#     end

#     it 'backs up selections for each product attribute selections as a CSV in Google Folder', focus: false do
#       @service.back_up_product_attribute_selections(product_attribute_ids:)
#     end

#     it 'backs up both main details and selections', focus: false do
#       @service.back_up_product_attributes(product_attribute_ids:)
#     end

#     it 'lists all Product Attributes', focus: false do
#       res = @service.all_product_attributes
#       expect(res.count).to eq(135)
#     end
#   end
# end
