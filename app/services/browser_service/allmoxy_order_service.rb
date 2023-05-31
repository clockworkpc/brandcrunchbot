require 'colorize'

class BrowserService
  class AllmoxyOrderService < AllmoxyService
    def extract_finish_pricing(order:, product_orders:)
      order_number = order.order_number
      Rails.logger.info("Getting Finish Pricing for Order #{order_number}".yellow)
      response = @aas.order_finish_pricing_get(order_number:)
      aofps = BrowserService::AllmoxyOrderFinishPriceService.new(response:, order:, product_orders:)
      aofps.extract_finish_pricing
    end

    def update_or_create_order(order_hsh:, customer:, order: nil)
      if order
        Utils.assign_attr(order, :ship_date, order_hsh[:ship_date])
        Utils.assign_attr(order, :order_name, order_hsh[:ship_date])
        Utils.assign_attr(order, :total, order_hsh[:ship_date])
        order.save!
      else
        order = Order.create(
          customer_id: customer.id,
          order_number: order_hsh[:order_number],
          ship_date: order_hsh[:ship_date],
          order_name: order_hsh[:order_name],
          total: order_hsh[:total]
        )
      end

      order_number = order.order_number
      @aohs.update_status_history(order_number:) if order.status_history.nil?

      order
    end

    def find_or_create_order(order_hsh:)
      customer = Customer.find_or_create_by(
        allmoxy_id: order_hsh[:company_number],
        customer_name: order_hsh[:company_name]
      )

      order = Order.find_by(
        customer_id: customer.id,
        order_number: order_hsh[:order_number]
      )

      update_or_create_order(order_hsh:, customer:, order:)
    end

    def update_or_create_product_order(order_id:, product_id:, product_order_hsh:, product_order: nil)
      if product_order
        Utils.assign_attr(product_order, :qty, product_order_hsh[:qty])
        product_order.save!
      else
        product_order = ProductOrder.create(
          order_id:,
          product_id:,
          finish_detail_id: FinishDetail.first.id,
          line_subtotal: product_order_hsh[:line_subtotal],
          finish_price: product_order_hsh[:finish_price] || 0,
          qty: product_order_hsh[:qty]
        )
      end

      product_order
    end

    def find_or_create_product_order(order_id:, product_id:, product_order_hsh:)
      line_subtotal = product_order_hsh[:line_subtotal]

      product_order = ProductOrder.find_by(
        order_id:,
        product_id:,
        line_subtotal:
      )

      update_or_create_product_order(order_id:, product_id:, product_order_hsh:, product_order:)
    end

    def extract_finish_records(order:, product_orders:)
      order_number = order.order_number
      Rails.logger.info("Getting Finish Pricing for Order #{order_number}".yellow)
      order_number = order.order_number
      response = @aas.order_finish_pricing_get(order_number:)
      aofps = BrowserService::AllmoxyOrderFinishPriceService.new(response:, order:, product_orders:)
      aofps.extract_finish_records
    end

    def find_or_create_orders_and_product_orders(order_hsh_ary:)
      order_hsh_ary.each do |hsh|
        if Order.exists?(order_number: hsh[:order][:order_number])
          Rails.logger.info("Order ##{hsh[:order][:order_number]} already exists in the DB")
          puts("Order ##{hsh[:order][:order_number]} already exists in the DB")
          next
        end

        order_hsh = hsh[:order]
        product_order_hsh_ary = hsh[:product_orders]

        order = find_or_create_order(order_hsh:)
        order_id = order.id

        product_orders = product_order_hsh_ary.map do |product_order_hsh|
          product = Product.find_or_create_by(
            product_id: product_order_hsh[:product_number],
            product_name: product_order_hsh[:product_name]
          )
          product_id = product.id
          find_or_create_product_order(order_id:, product_id:, product_order_hsh:) # TODO
        end

        extract_finish_records(order:, product_orders:)
      end
    end

    def generate_order_records(csv_path:)
      @browser = Utils.watir_browser
      @aohs = BrowserService::AllmoxyOrderHistoryService.new(@browser, true)
      Rails.logger.info('Creating CSV Object')
      csv = CSV.table(csv_path)
      Rails.logger.info('Generating Orders Hash Array')
      order_hsh_ary = Utils.create_orders_hash_array(csv:)
      Rails.logger.info('Orders Hash Array generated, updating Orders and Product Orders...')
      find_or_create_orders_and_product_orders(order_hsh_ary:)
    end
  end
end
