require 'colorize'

class BrowserService
  class AllmoxyOrderFinishPriceService # rubocop:disable Metrics/ClassLength
    class AllmoxyError < StandardError
    end

    def initialize(response:, order:, product_orders:)
      @doc = Nokogiri::HTML(response.body)
      @order = order
      @product_orders = product_orders
    end

    def default_finish_detail
      @default_finish_detail ||= FinishDetail.find_or_create_by(
        finish_type: nil,
        finish_color: nil,
        finish_sheen: nil
      )
    end

    def cv_finish_hash
      {
        'Finish Type' => 'C-V Finish',
        'Finish Sheen' => 'C-V Finish',
        'Finish Color' => 'C-V Finish'
      }
    end

    def finish_string_array(finish_tds:)
      finish_tds
        .map(&:text)
        .map { |str| str.delete("\n").delete("\t") }
        .grep_v(/Comments|comments/)
    end

    def finish_headers?(finish_str_ary:)
      header_check = ->(str) { finish_str_ary.join.match?(str) }
      header_check.call('Finish Type') &&
        header_check.call('Finish Sheen') &&
        header_check.call('Finish Color')
    end

    def finish_detail_hash(fieldset:)
      finish_tds = fieldset.xpath('.//div[@class="pao_td"]')

      cv_finish = finish_tds.find { |f| f.text.match?('C-V Finish') }
      return cv_finish_hash if cv_finish

      return if finish_tds.count < 3

      finish_str_ary = finish_string_array(finish_tds:)

      return unless finish_headers?(finish_str_ary:)

      finish_str_ary.to_h { |str| str.split(':') }
    end

    def extract_finish_detail(fieldset:)
      finish_detail_hsh = finish_detail_hash(fieldset:)

      return default_finish_detail unless finish_detail_hsh

      finish_type = finish_detail_hsh['Finish Type']

      return default_finish_detail if finish_type.eql?('No Finish')

      finish_color = finish_detail_hsh['Finish Color']
      finish_sheen = finish_detail_hsh['Finish Sheen']

      FinishDetail.find_or_create_by(
        finish_type:,
        finish_color:,
        finish_sheen:
      )
    end

    def extract_finish_price(fieldset:, finish_detail:)
      return 0 if finish_detail.finish_type.nil?

      sums_table = fieldset.xpath('.//table[@class="sums"]').first
      return 0 if sums_table.nil?

      sums_table.xpath('.//td[@class="tar"]').first.text.to_f
    end

    def extract_product_name(fieldset:)
      fieldset.xpath('.//legend').first.text.delete(':').strip
    end

    def extract_line_subtotal(fieldset:)
      total_footer = fieldset.xpath('.//tbody[@class="total footer"]').first
      total_footer.text.scan(/\$[0-9\.,]+/).first.delete('$').delete(',').to_d
    end

    def finish_records_hash_array
      fieldsets = @doc.xpath('//fieldset[@class="cutlist"]')
      Rails.logger.info("There are #{fieldsets.count} fieldsets for Order #{@order.order_number}".yellow)
      fieldsets.map do |fieldset|
        finish_detail = extract_finish_detail(fieldset:)
        finish_price = extract_finish_price(fieldset:, finish_detail:)
        product_name = extract_product_name(fieldset:)
        line_subtotal = extract_line_subtotal(fieldset:)

        {
          finish_detail:,
          product_name:,
          line_subtotal:,
          finish_price:
        }
      end
    end

    def add_finish_equal_count(finish_records:)
      @product_orders.each do |product_order|
        hsh = finish_records.find { |fr| fr[:product_name].delete(':') == product_order.product_name.delete(':') }
        begin
          product_order.finish_detail_id = hsh[:finish_detail].id unless hsh[:finish_detail].id.nil?
          product_order.finish_price = hsh[:finish_price]
          product_order.save!
        rescue NoMethodError
          Rails.logger.info("Could not find matching Finish Record for #{product_order.product_name} ")
        end
      end
    end

    def add_finish_unequal_count(finish_records:)
      @product_orders.each do |product_order|
        hsh_ary = finish_records.find_all do |fr|
          fr[:product_name].delete(':') == product_order.product_name.delete(':')
        end

        sum_finish_price = hsh_ary.sum { |fr| fr[:finish_price] }
        product_order.finish_price = sum_finish_price

        finish_record = hsh_ary.reject { |fr| fr[:finish_detail] == default_finish_detail }.first
        product_order.finish_detail_id = finish_record[:finish_detail].id unless finish_record.nil?
        product_order.save!
      end
    end

    def extract_finish_records
      finish_records = finish_records_hash_array

      if finish_records.count == @product_orders.count
        add_finish_equal_count(finish_records:)
      elsif finish_records.count > @product_orders.count
        add_finish_unequal_count(finish_records:)
      else
        begin
          raise AllmoxyError, 'More product order line items than fieldsets'
        rescue AllmoxyError
          Rails.logger.info("Skipping finish pricing for Order #{@order.order_number} ")
        end
      end
    end
  end
end
