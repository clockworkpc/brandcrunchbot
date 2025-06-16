require 'rails_helper'

RSpec.describe Auction, type: :model do
  describe 'database schema' do
    it 'has the expected columns with correct types and defaults' do
      columns = described_class.columns.index_by(&:name)
      bool = ActiveRecord::Type::Boolean.new

      expect(columns['domain_name'].type).to eq(:string)
      expect(columns['proxy_bid'].type).to eq(:integer)
      expect(columns['bin_price'].type).to eq(:integer)
      expect(columns['price'].type).to eq(:integer)
      expect(columns['auction_end_time'].type).to eq(:datetime)

      expect(columns['active'].type).to eq(:boolean)
      expect(bool.cast(columns['active'].default)).to eq(true)
      expect(columns['active'].null).to eq(false)

      expect(columns['is_valid'].type).to eq(:boolean)
      expect(bool.cast(columns['is_valid'].default)).to eq(true)
      expect(columns['is_valid'].null).to eq(false)

      expect(columns['created_at'].type).to eq(:datetime)
      expect(columns['created_at'].null).to eq(false)

      expect(columns['updated_at'].type).to eq(:datetime)
      expect(columns['updated_at'].null).to eq(false)
    end
  end

  describe 'default values' do
    subject(:auction) { described_class.new }

    it 'defaults active to true' do
      expect(auction.active).to be(true)
    end

    it 'defaults is_valid to true' do
      expect(auction.is_valid).to be(true)
    end
  end
end

