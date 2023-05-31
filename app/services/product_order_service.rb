class ProductOrderService
  def initialize(google_sheets_api_instance)
    @gsa = google_sheets_api_instance
  end

  def finish_pricing_attributes
    %w[
      order_number
      customer_name
      ship_date
      completed_at
      product_name
      line_subtotal
      finish_price
      qty
    ]
  end

  def finish_product_orders_sql
    [
      'product_orders.*',
      'customers.customer_name AS customer_name',
      'orders.order_number AS order_number',
      'orders.ship_date AS ship_date',
      'orders.completed_at AS completed_at',
      'products.product_name AS product_name'
    ].join(', ')
  end

  def finish_product_orders_qr(start_date:, end_date:, gs_order_numbers: [])
    ProductOrder
      .select(finish_product_orders_sql)
      .joins(order: :customer)
      .joins(:product)
      .joins(:finish_detail)
      .order(:order_number)
      .where(orders: { ship_date: start_date..end_date })
      .where.not(orders: { order_number: gs_order_numbers })
  end

  def create_csv_object(finish_product_orders:)
    attributes = finish_pricing_attributes

    csv_string = CSV.generate(headers: true) do |csv|
      csv << attributes
      finish_product_orders.each do |fpo|
        csv << attributes.map { |attr| fpo.send(attr) }
      end
    end
    CSV.parse(csv_string)
  end

  def extant_order_numbers(spreadsheet_id:, range:)
    order_numbers_column = range.sub(/!.*$/, '!A2:A')
    current_sheet = @gsa.get_spreadsheet_values(spreadsheet_id:,
                                                range: order_numbers_column)
    return [] if current_sheet.values.nil?

    current_sheet.values.map { |row| row.first.to_i }.uniq
  end

  def fresh_db_values(spreadsheet_id:, start_date:, end_date:, range:)
    gs_order_numbers = extant_order_numbers(spreadsheet_id:, range:)
    finish_product_orders = finish_product_orders_qr(start_date:, end_date:, gs_order_numbers:)
    create_csv_object(finish_product_orders:)
  end

  def update_finish_price_tracking(spreadsheet_id:, start_date:, end_date:, range: 'finish_orders!A1:H')
    db_values = fresh_db_values(spreadsheet_id:, start_date:, end_date:, range:)
    values = db_values.drop(1) # first element is the header row
    diff_order_numbers = values.map(&:first).uniq.sort
    Rails.logger.info("Orders to append: #{diff_order_numbers}")
    Rails.logger.info("#{values.count} product orders to append")
    @gsa.append_spreadsheet_value(spreadsheet_id:, range:, values:)
  end
end
