require 'rails_helper'

RSpec.describe Utils do
  let(:csv_path) { 'app/assets/config/allmoxy_product_tags.csv' }

  let(:door_kv) do
    { 'Door' =>
      { sanded: true,
        '5pc': true,
        solidwood: true,
        cnc: false,
        specialty: false,
        boxes: false } }
  end

  let(:door_values) { %w[sanded 5pc solidwood] }

  let(:foobar_path) { 'spec/fixtures/foobar' }

  let(:orders_hash_array) do
    [
      {
        order: {
          order_number: 65_693,
          company_number: 845,
          company_name: 'NW Cabinetry',
          order_name: 'NWC00138',
          total: 1153.91,
          ship_date: '2022-10-26'
        },
        product_orders: [
          {
            product_number: 451,
            product_name: 'Door - MDF Core Panel',
            qty: 8,
            line_subtotal: 394.46
          },
          {
            product_number: 454,
            product_name: 'Door - Glass Prepped',
            qty: 8,
            line_subtotal: 500.84
          },
          {
            product_number: 466,
            product_name: 'Drawer Front - Slab',
            qty: 7,
            line_subtotal: 192.61
          },
          {
            product_number: 469,
            product_name: 'Drawer Front - MDF Core Panel',
            qty: 2,
            line_subtotal: 66
          }
        ]
      },
      {
        order: {
          order_number: 78_775,
          company_number: 342,
          company_name: 'Clearwater Builders LLC',
          order_name: 'fin-Loren Beverage Drawers',
          total: 147.45,
          ship_date: '2022-10-07'
        },
        product_orders: [
          {
            product_number: 488,
            product_name: 'Drawer Box - Dovetail',
            qty: 2,
            line_subtotal: 139.1
          }
        ]
      },
      {
        order: {
          order_number: 78_783,
          company_number: 1053,
          company_name: 'Core Cabinet LLC',
          order_name: 'FIN-Mitchell Door',
          total: 82.97,
          ship_date: '2022-10-18'
        },
        product_orders: [
          {
            product_number: 451,
            product_name: 'Door - MDF Core Panel',
            qty: 1,
            line_subtotal: 82.97
          }
        ]
      }
    ]
  end

  describe 'Date Strings' do
    it 'returns a date string' do
      expect(described_class.date_string(month: 1, day: 1, year: 2020)).to eq('2020-01-01')
    end

    it 'returns the first day two months ago' do
      res = described_class.first_day_two_months_ago.split('-')
      tma = DateTime.now.months_ago(2)
      expect(res[0].to_i).to eq(tma.year)
      expect(res[1].to_i).to eq(tma.month)
      expect(res[2].to_i).to eq(1)
    end

    it 'returns the first day two months ago for a supplied date' do
      res = described_class.first_day_two_months_ago(month: 1, day: 20, year: 2000).split('-')
      expect(res[0].to_i).to eq(1999)
      expect(res[1].to_i).to eq(11)
      expect(res[2].to_i).to eq(20)
    end

    it 'returns the last day two months hence' do
      res = described_class.last_day_two_months_hence.split('-')
      tma = DateTime.now.months_since(2)
      expect(res[0].to_i).to eq(tma.year)
      expect(res[1].to_i).to eq(tma.month)
      expect(res[2].to_i).to eq(tma.end_of_month.day)
    end

    it 'creates an Orders Hash', focus: false do
      orders_csv_path = 'spec/fixtures/completed_orders_report.csv'
      csv = CSV.table(orders_csv_path)
      res = described_class.create_orders_hash_array(csv:)
      expect(res).to eq(orders_hash_array)
    end

    it 'returns working days to date', focus: false do
      res = described_class.working_days_to_date
    end

    it 'returns a Hash for this week', focus: false do
      res = described_class.this_week
      expect(res[:start_date]).to eq(Date.current.monday.iso8601)
      expect(res[:end_date]).to eq(Date.current.sunday.iso8601)
    end

    it 'returns all weeks for this year', focus: false do
      res = described_class.start_dates_this_year
      expect(res.first).to eq(Date.parse('2023-01-02'))
      expect(res.last).to eq(Date.parse('2023-12-25'))
      expect(res.count).to eq(52)
    end

    it 'returns all start dates to date', focus: true do
      today = Date.current
      monday = today.monday? ? today.iso8601 : today.prev_occurring(:monday).iso8601
      res = described_class.start_dates_to_date
      expect(res.first).to eq(Date.parse('2023-01-02'))
      expect(res.last).to eq(Date.parse(monday))
    end

    # it 'reads CSV booleans', focus: false do
    #   res = described_class.read_booleans_from_csv(csv_path)
    #   expect(res['Door']).to eq(door_kv['Door'])
    # end

    # it 'reads true values from CSV booleans', focus: false do
    #   res = described_class.read_true_booleans_from_csv(csv_path)
    #   expect(res['Door']).to eq(door_values)
    # end

    # it 'plays a sound when invoking notify-send' do
    #   described_class.notify_send('hello world')
    #   sleep 1
    #   described_class.notify_send('coin', :coin)
    #   sleep 1
    #   described_class.notify_send('complete', :coin)
    # end

    # it 'lists files without duplicates', focus: false do
    #   res = described_class.list_files_without_duplicates(path: foobar_path, scan_int: 3)
    #   expect(res.count).to eq(2)
    #   basenames = res.map { |f| File.basename(f) }
    #   expect(basenames).to eq(%w[foobar1_3 foobar2_3])
    # end

    # it 'lists files with extra characters without duplicates', focus: true do
    #   res = described_class.list_files_without_duplicates(path: csv_path, scan_int: 7)
    #   expect(res.count).to eq(135)
    # end
  end
end
