require 'rails_helper'

RSpec.describe AllmoxyApiBeta::ProductService do
  let(:products_json) { JSON.parse(File.read('spec/fixtures/allmoxy_api_beta/products.json')) }

  before(:all) do
    @service = described_class.new
  end

  describe 'GET Requests' do
    it 'gets all products', focus: true do
      res = @service.products
      expect(res).to eq(products_json)
      expect(res['entries']).not_to be_empty
    end

    it 'gets product WHERE product_id=4', focus: true do
      res, entry = test_entry(product_id: 4)
      expect(res).to eq(entry)
    end

    it 'gets product WHERE product_id=8', focus: true do
      res, entry = test_entry(product_id: 8)
      expect(res).to eq(entry)
    end

    it 'gets product WHERE product_id=9', focus: true do
      res, entry = test_entry(product_id: 9)
      expect(res).to eq(entry)
    end
  end

  def find_entry(product_id)
    products_json['entries'].find { |e| e['product_id'] == product_id }
  end

  def test_entry(product_id:)
    res = @service.products(product_id:)
    entry = find_entry(product_id)
    [res, entry]
  end
end
