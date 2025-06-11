require 'rails_helper'
require 'timecop'

RSpec.describe Utils do
  describe '.date_string' do
    it 'pads month and day with leading zeros' do
      expect(described_class.date_string(month: 2, day: 3, year: 2025)).to eq '2025-02-03'
    end

    it 'defaults year to current year' do
      Timecop.freeze(DateTime.new(2024, 5, 6)) do
        expect(described_class.date_string(month: 1, day: 2)).to eq '2024-01-02'
      end
    end
  end

  describe '.first_day_two_months_ago' do
    before { Timecop.freeze(DateTime.new(2025, 6, 15)) }
    after  { Timecop.return }

    context 'without arguments' do
      it 'returns the first day two months ago from today' do
        # From June 15, 2025 → April 1, 2025
        expect(described_class.first_day_two_months_ago).to eq '2025-04-01'
      end
    end

    context 'with specific date arguments' do
      it 'computes based on provided date' do
        expect(described_class.first_day_two_months_ago(month: 6, day: 10, year: 2025)).to eq '2025-04-10'
      end
    end
  end

  describe '.last_day_two_months_hence' do
    before { Timecop.freeze(DateTime.new(2025, 6, 15)) }
    after  { Timecop.return }

    context 'without arguments' do
      it 'returns the last day two months from today' do
        # From June 15, 2025 → August 31, 2025
        expect(described_class.last_day_two_months_hence).to eq '2025-08-31'
      end
    end

    context 'with specific date arguments' do
      it 'computes based on provided date' do
        expect(described_class.last_day_two_months_hence(month: 1, day: 30, year: 2025)).to eq '2025-03-30'
      end
    end
  end

  describe '.to_bool' do
    it 'returns true for "true" (case-insensitive)' do
      expect(described_class.to_bool('TrUe')).to be true
    end

    it 'returns false for "false" (case-insensitive)' do
      expect(described_class.to_bool('FALSE')).to be false
    end

    it 'returns nil for non-boolean strings or non-strings' do
      expect(described_class.to_bool('yes')).to be_nil
      expect(described_class.to_bool(123)).to be_nil
    end
  end

  describe '.finish_price_percentage' do
    it 'returns 100 when total_price is zero' do
      expect(described_class.finish_price_percentage(total_price: 0, finish_price_total: 5)).to eq 100
    end

    it 'calculates percentage correctly' do
      result = described_class.finish_price_percentage(total_price: '200', finish_price_total: '50')
      expect(result).to eq 25.0
    end
  end

  describe '.create_orders_hash_array' do
    let(:csv_rows) do
      [
        { order: 1, company: 10, company_name: 'Alpha', order_name: 'Test1', total: '100', ship_date: '2025-06-01', product: 'P1', product_name: 'Widget', qty: '2', line_subtotal: '40' },
        { order: 1, company: 10, company_name: 'Alpha', order_name: 'Test1', total: '100', ship_date: '2025-06-01', product: 'P2', product_name: 'Gadget', qty: '1', line_subtotal: '60' },
        { order: 2, company: 20, company_name: 'Beta',  order_name: 'Test2', total: '200', ship_date: '2025-06-02', product: 'P3', product_name: 'Thingamajig', qty: '5', line_subtotal: '200' }
      ]
    end

    it 'groups products under their respective orders' do
      result = described_class.create_orders_hash_array(csv: csv_rows)
      expect(result.size).to eq 2

      first_order = result.find { |h| h[:order][:order_number] == 1 }
      expect(first_order[:product_orders].map { |po| po[:product_name] }).to contain_exactly('Widget', 'Gadget')

      second_order = result.find { |h| h[:order][:order_number] == 2 }
      expect(second_order[:product_orders].first[:product_name]).to eq('Thingamajig')
    end
  end

  # describe '.assign_attr' do
  #   let(:obj) { OpenStruct.new(name: 'Alice') }
  #
  #   it 'returns the object unchanged when value matches' do
  #     returned = described_class.assign_attr(obj, :name, 'Alice')
  #     expect(returned).to be obj
  #   end
  #
  #   it 'assigns attribute when value differs' do
  #     obj2 = OpenStruct.new(name: 'Bob')
  #     returned = described_class.assign_attr(obj2, :name, 'Carol')
  #     expect(returned.name).to eq 'Carol'
  #   end
  # end

  describe '.force_utf8_encoding' do
    it 'replaces invalid byte sequences' do
      invalid = "\xFF".b
      result = described_class.force_utf8_encoding(invalid)
      expect(result.encoding).to eq Encoding::UTF_8
      expect(result).to be_a(String)
    end
  end

  describe '.simple_datestamp' do
    it 'returns today in YYYY-MM-DD format' do
      Timecop.freeze(DateTime.new(2025, 6, 11)) do
        expect(described_class.simple_datestamp).to eq '2025-06-11'
      end
    end
  end

  describe '.this_week' do
    it 'returns monday to sunday of current week' do
      Timecop.freeze(Date.new(2025, 6, 11)) do # Wednesday
        week = described_class.this_week
        expect(week[:start_date]).to eq '2025-06-09' # Monday
        expect(week[:end_date]).to eq '2025-06-15'   # Sunday
      end
    end
  end

  describe '.start_dates_this_year' do
    it 'includes only Mondays in the year' do
      dates = described_class.start_dates_this_year
      expect(dates).to all(satisfy { |d| d.monday? })
      expect(dates.first).to eq(Date.parse('2023-01-02'))
    end
  end

  describe '.start_dates_to_date' do
    it 'only includes past or today dates' do
      allow(Date).to receive(:current).and_return(Date.parse('2023-06-30'))
      dates = described_class.start_dates_to_date
      expect(dates).to all(be <= Date.current)
    end
  end
end
