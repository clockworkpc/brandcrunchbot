class AllmoxyApiBeta
  class OrderService < AllmoxyApiBeta
    ORDER_TEMPLATE = JSON.parse(File.read('spec/fixtures/allmoxy_api_beta/order_template.json')).deep_symbolize_keys

    def orders(order_id: nil)
      get_response(path: get_path(__method__, order_id))
    end

    def order_body(hsh)
      body = {}
      ORDER_TEMPLATE.each do |k, v|
        body[k] = hsh.key?(k) ? hsh[k] : v
      end
      body
    end

    # :name=>"FooBar 202304281600",
    # :description=>nil,
    # :company_id=>0,
    # :contact_id=>7,
    # :entered_by_id=>2,
    # :order_type=>"order",
    # :tax_rate=>"0.000",
    # :tax_rate_override=>nil,
    # :gst_rate=>nil,
    # :gst_rate_override=>nil,
    # :pst_rate=>nil,
    # :pst_rate_override=>nil,
    # :shipping=>"0.00",
    # :shipping_override=>nil,
    # :profit=>nil,
    # :discount_percent=>nil,
    # :price=>"38.93",
    # :b2b_subtotal=>nil,
    # :b2b_shipping=>nil,
    # :entered_date=>"2023-04-28T12:59:08",
    # :last_edit_date=>"2023-05-11T12:51:13",
    # :last_edit_id=>2,
    # :last_edit_ip=>"10.0.0.170",
    # :start_date=>nil,
    # :finish_date=>nil,
    # :desired_delivery_date=>nil,
    # :actual_delivery_date=>"2023-05-31T12:59:00",
    # :billing_name=>"Retail",
    # :billing_address1=>"1234 Street",
    # :billing_address2=>"1234 Street",
    # :billing_address3=>nil,
    # :billing_city=>"Yourcity",
    # :billing_state=>"AK",
    # :billing_zip=>"11111",
    # :billing_country=>"United States",
    # :shipping_same_as_billing=>0,
    # :shipping_name=>nil,
    # :shipping_attn=>nil,
    # :shipping_address1=>nil,
    # :shipping_address2=>nil,
    # :shipping_address3=>nil,
    # :shipping_city=>nil,
    # :shipping_state=>nil,
    # :shipping_zip=>nil,
    # :shipping_country=>nil,
    # :shipping_instructions=>nil,
    # :shipping_method=>0,
    # :shipping_data=>{:fq_carrier_name=>"", :fq_quote_id=>"", :fq_carrier_option_id=>"", :fq_shipping_price=>""},
    # :tracking_data=>nil,
    # :tax_shipping=>0,
    # :is_remake=>0,
    # :b2b_guest=>nil,
    # :b2b_dropship=>1,
    # :b2b_reseller_agree=>0,
    # :designer_project_id=>nil,
    # :saved_presets=>nil,
    # :status=>"verified",
    # :timestamp=>"2023-05-11T12:51:13",
    # :createdby=>"sandbox",
    # :createdbyid=>2,
    # :createddate=>"2023-04-28T12:59:08",
    # :updatedby=>"sandbox",
    # :updatedbyid=>2,
    # :updateddate=>"2023-05-11T12:51:13",
    # :contact_first_name=>"Simon",
    # :contact_last_name=>"Simonson",
    # :company_name=>"Retail",
    # :entered_by_first_name=>"Alexander",
    # :entered_by_last_name=>"Garber"}

    def create_order(body:)
      body = order_body(body)
      path = 'orders'
      post_response(path:, body:)
    end
  end
end
