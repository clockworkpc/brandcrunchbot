require 'rails_helper'

RSpec.describe AllmoxyApiBeta do
  let(:addresses_json) { JSON.parse(File.read('spec/fixtures/allmoxy_api_beta/addresses.json')) }

  before(:all) do
    @service = described_class.new
  end

  describe 'GET Requests' do
    describe 'Addresses' do
      it 'gets all addresses', focus: false do
        res = @service.get_response(path: :addresses)
        expect(res).to eq(addresses_json)
      end

      it 'gets address WHERE address_id=2', focus: false do
        path = @service.get_path(:addresses, 2)
        res = @service.get_response(path:)
        expect(res).to eq(addresses_json['entries'][1])
      end
    end
  end
end
