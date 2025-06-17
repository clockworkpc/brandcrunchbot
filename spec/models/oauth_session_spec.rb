require 'rails_helper'

RSpec.describe OauthSession, type: :model do
  describe 'database columns' do
    it 'has the expected columns' do
      columns = described_class.columns.index_by(&:name)

      expect(columns['code'].type).to eq(:string)
      expect(columns['scope'].type).to eq(:string)
      expect(columns['created_at'].null).to be(false)
      expect(columns['updated_at'].null).to be(false)
    end
  end
end
