require 'rails_helper'

RSpec.describe AllmoxyApiBeta::TriggerService do
  let(:triggers_json) { JSON.parse(File.read('spec/fixtures/allmoxy_api_beta/triggers.json')) }

  before do
    @service = described_class.new
  end

  describe 'GET Requests' do
    describe 'Triggers' do
      it 'gets all triggers', focus: true do
        res = @service.triggers
        # expect(res).to eq(triggers_json)
        expect(res['entries']).not_to be_empty
      end

      # NOTE: Contains nested JSON
      it 'gets trigger WHERE trigger_id=1', focus: false do
        res = @service.triggers(trigger_id: 28)
        expect(res).to eq(triggers_json['entries'][0])
      end
    end
  end
end
