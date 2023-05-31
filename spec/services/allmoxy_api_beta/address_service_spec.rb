require 'rails_helper'

RSpec.describe AllmoxyApiBeta::AddressService do
  let(:addresses_json) { JSON.parse(File.read('spec/fixtures/allmoxy_api_beta/addresses.json')) }

  before do
    @service = described_class.new
  end

  describe 'GET Requests' do
    describe 'Addresses' do
      it 'gets all addresses', focus: true do
        res = @service.addresses
        expect(res).to eq(addresses_json)
        expect(res['entries']).not_to be_empty
      end

      it 'gets address WHERE address_id=1', focus: true do
        res, entry = test_entry(address_id: 1)
        expect(res).to eq(entry)
      end

      it 'gets address WHERE address_id=2', focus: true do
        res, entry = test_entry(address_id: 2)
        expect(res).to eq(entry)
      end

      it 'gets address WHERE address_id=3', focus: true do
        res, entry = test_entry(address_id: 3)
        expect(res).to eq(entry)
      end

      it 'gets address WHERE address_id=4', focus: true do
        res, entry = test_entry(address_id: 4)
        expect(res).to eq(entry)
      end
    end
  end

  def find_entry(address_id)
    addresses_json['entries'].find { |e| e['address_id'] == address_id }
  end

  def test_entry(address_id:)
    res = @service.addresses(address_id:)
    entry = find_entry(address_id)
    [res, entry]
  end
end
