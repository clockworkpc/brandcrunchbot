require 'rails_helper'

RSpec.describe AllmoxyApiBeta::TagService do
  let(:tags_json) { JSON.parse(File.read('spec/fixtures/allmoxy_api_beta/tags.json')) }

  before do
    @service = described_class.new
  end

  describe 'GET Requests' do
    # FIXME: No records
    describe 'Tags' do
      it 'gets all tags', focus: true do
        res = @service.tags
        Clipboard.copy JSON.generate(res)
        expect(res).to eq(tags_json)
        expect(res['entries']).not_to be_empty
      end

      # FIXME: No records
      it 'gets tag WHERE tag_id=1', focus: true do
        res = @service.tags(tag_id: 28)
        expect(res).to eq(tags_json['entries'][0])
      end
    end
  end
end
