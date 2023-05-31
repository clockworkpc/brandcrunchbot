require 'rails_helper'

RSpec.describe AllmoxyApiBeta::ContactService do
  let(:contacts_json) { JSON.parse(File.read('spec/fixtures/allmoxy_api_beta/contacts.json')) }

  before(:all) do
    @service = described_class.new
  end

  describe 'GET Requests' do
    describe 'Contacts' do
      it 'gets all contacts', focus: true do
        res = @service.contacts
        expect(res).to eq(contacts_json)
        expect(res['entries']).not_to be_empty
      end

      # FIXME: This request returns an authorization error
      it 'gets contact WHERE contact_id=1', focus: true do
        res, entry = test_entry(contact_id: 1)
        expect(res).to eq(entry)
      end

      it 'gets contact WHERE contact_id=2', focus: true do
        res, entry = test_entry(contact_id: 2)
        expect(res).to eq(entry)
      end

      it 'gets contact WHERE contact_id=3', focus: true do
        res, entry = test_entry(contact_id: 3)
        expect(res).to eq(entry)
      end
    end
  end

  def find_entry(contact_id)
    contacts_json['entries'].find { |e| e['contact_id'] == contact_id }
  end

  def test_entry(contact_id:)
    res = @service.contacts(contact_id:)
    entry = find_entry(contact_id)
    [res, entry]
  end
end
