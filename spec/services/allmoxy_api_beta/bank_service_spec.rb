require 'rails_helper'

RSpec.describe AllmoxyApiBeta::BankService do
  let(:banks_json) { JSON.parse(File.read('spec/fixtures/allmoxy_api_beta/banks.json')) }

  before(:all) do
    @service = described_class.new
  end

  describe 'GET Requests' do
    describe 'Banks' do
      it 'gets all banks', focus: true do
        res = @service.banks
        expect(res).to eq(banks_json)
        expect(res['entries']).not_to be_empty
      end
    end
  end
end
