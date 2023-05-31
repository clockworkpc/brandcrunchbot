require 'logger'
require 'httparty'
require 'securerandom'
require 'uri'
require 'net/http'
require 'open-uri'

class AllmoxyApiService # rubocop:disable Metrics/ClassLength
  attr_reader :browser, :s, :h, :phpsessid

  BASE_URL = 'https://panhandledooranddrawer.allmoxy.com'.freeze
  ORDERS_REPORT_URL = [BASE_URL, 'reports', 'orders/'].join('/').freeze
  ORDERS_REPORT_CSV_URL = [BASE_URL, 'reports', 'orders', 'export/'].join('/').freeze
  SHIPPING_REPORT_URL = [BASE_URL, 'reports', 'delivery/'].join('/').freeze
  SHIPPING_REPORT_CSV_URL = [BASE_URL, 'reports', 'delivery', 'export/'].join('/').freeze
  REMAKE_REPORT_URL = [BASE_URL, 'reports', 'remakes/'].join('/').freeze
  REMAKE_REPORT_CSV_URL = [BASE_URL, 'reports', 'remakes', 'export/'].join('/').freeze
  PRODUCTS_URL = [BASE_URL, 'catalog', 'products/'].join('/').freeze
  PRODUCTS_CSV_URL = [BASE_URL, 'catalog', 'products', 'csv/'].join('/').freeze
  PRODUCT_EDIT_URL = [BASE_URL, 'catalog', 'products', 'edit'].join('/').freeze
  PRODUCT_LABEL_URL = [BASE_URL, 'catalog', 'products', 'labels'].join('/').freeze
  PRODUCT_PARTS_URL = [BASE_URL, 'catalog', 'products', 'parts'].join('/').freeze
  PRODUCT_CLONE_URL = [BASE_URL, 'catalog', 'products', 'clone'].join('/').freeze
  PRODUCT_ATTRIBUTES_URL = [BASE_URL, 'catalog', 'attributes/'].join('/').freeze
  PRODUCT_ATTRIBUTES_CSV_URL = [BASE_URL, 'catalog', 'attributes', 'csv/'].join('/').freeze
  PRODUCT_ATTRIBUTE_URL = [BASE_URL, 'catalog', 'attributes'].join('/').freeze
  PRODUCT_ATTRIBUTE_EXPORT_URL = [BASE_URL, 'catalog', 'attributes', 'export_options'].join('/').freeze
  PROJECTION_REPORT_URL = [BASE_URL, 'reports', 'projection/'].join('/').freeze
  PROJECTION_REPORT_CSV_URL = [BASE_URL, 'reports', 'projection', 'export/'].join('/').freeze
  ORDER_URL = [BASE_URL, 'orders', 'output'].join('/').freeze
  COMPANIES_URL = [BASE_URL, 'accounts', 'companies/'].join('/').freeze
  COMPANIES_CSV_URL = [BASE_URL, 'export', 'contacts/'].join('/').freeze
  INDIVIDUALS_URL = [BASE_URL, 'export', 'people/'].join('/').freeze
  INDIVIDUALS_CSV_URL = [BASE_URL, 'export', 'people/'].join('/').freeze
  ORDER_HISTORY_URL = [BASE_URL, 'orders', 'status_history'].join('/').freeze
  STATUS_ORDER_HISTORY_URL = [BASE_URL, 'reports', 'status_history/'].join('/').freeze
  STATUS_ORDER_HISTORY_CSV_URL = [BASE_URL, 'reports', 'status_history', 'export/'].join('/').freeze

  include HTTParty
  base_uri(BASE_URL)
  debug_output

  def initialize(phpsessid)
    @phpsessid = phpsessid
    @allmoxy_constants = JSON.parse(File.read('app/assets/config/allmoxy_constants.json'))
    @order_tags = {}
    @allmoxy_constants['orders_report']['tags'].each { |hash| @order_tags[hash['caption']] = hash['value'] }
    @allmoxy_constants['orders_report']['statuses'].each { |hash| @order_tags[hash['caption']] = hash['value'] }
  end

  def force_utf8_encoding(str)
    str.encode(Encoding.find('UTF-8'), invalid: :replace, undef: :replace, replace: '')
  end

  def standard_headers(page:, verb:)
    hsh = @allmoxy_constants[page]['request_headers'][verb]
    hsh['Cookie'] = "PHPSESSID=#{@phpsessid}"
    hsh
  end

  def shipping_report_body(start_date:, end_date:, sort_col: 'actual_delivery_date', sort_dir: 'ASC')
    delivery_methods = @allmoxy_constants['shipping_report']['delivery_methods']

    hsh = {
      start_date:,
      end_date:
    }

    delivery_methods.each { |n| hsh["delivery_method[#{n}]".to_sym] = 1 }

    hsh[:tags] = ''
    hsh[:sort_col] = sort_col
    hsh[:sort_dir] = sort_dir
    hsh
  end

  def remake_report_body(start_date:, end_date:)
    delivery_methods = @allmoxy_constants['shipping_report']['delivery_methods']

    hsh = {
      start_date:,
      end_date:
    }

    delivery_methods.each { |n| hsh["delivery_method[#{n}]".to_sym] = 1 }

    hsh[:tags] = ''
    hsh
  end

  def status_history_report_body(start_date:, end_date:, group_by:, show_only_forward_movements:)
    {
      start_date:,
      end_date:,
      group_by:,
      show_only_forward_movements:
    }
  end

  def projection_report_body(start_date:, end_date:, order_statuses: ['verified', 'in progress'])
    export_classes = @allmoxy_constants['projection_report']['export_classes']

    hsh = {
      start_date:,
      end_date:
    }

    order_statuses.each { |n| hsh["status[#{n}]".to_sym] = 1 }
    export_classes.each { |n| hsh["export_class[#{n}]".to_sym] = 1 }
    hsh['tags'] = nil

    hsh
  end

  # TODO: statuses and tags
  def orders_report_body(start_date:, end_date:, statuses:)
    hsh = {}

    statuses.each { |status| hsh["status[#{status}]".to_sym] = '1' }

    hsh['selected_date'] = 'shipped'

    hsh['start_date'] = start_date
    hsh['end_date'] = end_date

    hsh
  end

  def product_label_body(label_div_id:, label_list_id:, html:)
    {
      "labels[#{label_div_id}][action]" => '1',
      "labels[#{label_div_id}][name]" => 'Thin Label',
      "labels[#{label_div_id}][list_id]" => label_list_id,
      "labels[#{label_div_id}][html]" => html
    }
  end

  def product_edit_body
  end

  def curly_brackets_and_quotes(caption:)
    curly_brackets = ->(str) { [CGI.escape('{'), str, CGI.escape('}')].join }
    quotes = ->(str) { [CGI.escape('"'), str, CGI.escape('"')].join }
    curly_brackets.call(
      [
        quotes.call('value'),
        CGI.escape(':'),
        quotes.call(@order_tags[caption]),
        CGI.escape(','),
        quotes.call('caption'),
        CGI.escape(':'),
        quotes.call(caption)
      ].join
    )
  end

  def enclose_in_encoded_characters(key:, captions:)
    square_brackets = ->(str) { [CGI.escape('['), str, CGI.escape(']')].join }

    joined_tags = if captions
                    escaped_tags = []
                    captions.each { |caption| escaped_tags << curly_brackets_and_quotes(caption:) }
                    square_brackets.call(escaped_tags.join(CGI.escape(',')))
                  end

    "#{key}=#{joined_tags}"
  end

  # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
  def orders_report_body_add_tags(encoded_body:,
                                  tags_any_order:,
                                  tags_all_order:,
                                  tags_none_order:,
                                  tags_any_company:,
                                  tags_all_company:,
                                  tags_none_company:,
                                  tags_any_product:,
                                  tags_all_product:,
                                  tags_none_product:)

    add_tags = lambda do |key, captions|
      enclose_in_encoded_characters(key:, captions:)
    end

    [
      'name=',
      encoded_body,
      add_tags.call('tags_any_Order', tags_any_order),
      add_tags.call('tags_all_Order', tags_all_order),
      add_tags.call('tags_none_Order', tags_none_order),
      add_tags.call('tags_any_Company', tags_any_company),
      add_tags.call('tags_all_Company', tags_all_company),
      add_tags.call('tags_none_Company', tags_none_company),
      add_tags.call('tags_any_Product', tags_any_product),
      add_tags.call('tags_all_Product', tags_all_product),
      add_tags.call('tags_none_Product', tags_none_product)
    ]
      .join('&')
  end
  # rubocop:enable Metrics/MethodLength, Metrics/ParameterLists

  def add_request_headers(request:, page:, verb:)
    # as = BrowserService::AllmoxyService.new
    # phpsessid = as.retrieve_phpsessid_via_http_call
    # puts Rainbow("phpsessid = #{phpsessid}").green
    # hsh = @allmoxy_constants[page]['request_headers'][verb]
    # hsh['Cookie'] = "PHPSESSID=#{phpsessid}"
    # hsh.each { |k, v| request[k] = v }
    puts Rainbow("phpsessid = #{@phpsessid}").green
    hsh = @allmoxy_constants[page]['request_headers'][verb]
    hsh['Cookie'] = "PHPSESSID=#{@phpsessid}"
    hsh.each { |k, v| request[k] = v }
    request
  end

  def write_report_csv_to_file(response:, report:)
    filename = "tmp/#{report}_report_#{DateTime.now.iso8601}.csv"
    f = File.open(filename, 'w')
    utf8_encoded_body = force_utf8_encoding(response.body)
    f.write(utf8_encoded_body)
    f.close
    Rails.logger.info("CSV Path: #{filename}".yellow)
    filename
  end

  def write_products_csv_to_file(response:)
    filename = "tmp/products_#{DateTime.now.iso8601}.csv"
    f = File.open(filename, 'w')
    utf8_encoded_body = force_utf8_encoding(response.body)
    f.write(utf8_encoded_body)
    f.close
  end

  def write_product_attribute_selections_csv_to_file(response:, product_attribute_id:)
    Dir.mkdir('tmp/product_attributes') unless File.exist?('tmp/product_attributes')
    folder_path = "tmp/product_attributes/product_attributes-#{DateTime.now.strftime('%Y-%m-%d')}"
    Dir.mkdir(folder_path) unless File.exist?(folder_path)

    filename = "#{folder_path}/product_attribute_selectors-#{product_attribute_id}-#{DateTime.now.iso8601}.csv"
    f = File.open(filename, 'w')
    utf8_encoded_body = force_utf8_encoding(response.body)
    f.write(utf8_encoded_body)
    f.close
  end

  def shipping_report_get
    url = URI(SHIPPING_REPORT_URL)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    add_request_headers(request:, page: 'shipping_report', verb: 'get')
    https.request(request)
  end

  def shipping_report_post(start_date:, end_date:)
    url = URI(SHIPPING_REPORT_URL)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(url)
    add_request_headers(request:, page: 'shipping_report', verb: 'post')
    form_hash = shipping_report_body(start_date:, end_date:)
    request.body = URI.encode_www_form(form_hash)
    https.request(request)
  end

  def write_shipping_report_csv_to_file(response)
    write_report_csv_to_file(response:, report: 'shipping')
  end

  def shipping_report_csv
    url = URI(SHIPPING_REPORT_CSV_URL)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    add_request_headers(request:, page: 'shipping_report', verb: 'export')
    response = https.request(request)
    write_shipping_report_csv_to_file(response)
  end

  def remake_report_get
    url = URI(REMAKE_REPORT_URL)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    add_request_headers(request:, page: 'remake_report', verb: 'get')
    https.request(request)
  end

  def remake_report_post(start_date:, end_date:)
    url = URI(REMAKE_REPORT_URL)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(url)
    add_request_headers(request:, page: 'remake_report', verb: 'post')
    form_hash = remake_report_body(start_date:, end_date:)
    request.body = URI.encode_www_form(form_hash)
    https.request(request)
  end

  def write_remake_report_csv_to_file(response)
    write_report_csv_to_file(response:, report: 'remake')
  end

  def remake_report_csv
    url = URI(REMAKE_REPORT_CSV_URL)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    add_request_headers(request:, page: 'remake_report', verb: 'export')
    response = https.request(request)
    write_remake_report_csv_to_file(response)
  end

  def projection_report_post(start_date:, end_date:)
    url = URI(PROJECTION_REPORT_URL)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(url)
    add_request_headers(request:, page: 'projection_report', verb: 'post')
    form_hash = projection_report_body(start_date:, end_date:)
    request.body = URI.encode_www_form(form_hash)
    https.request(request)
  end

  def write_projection_report_csv_to_file(response)
    write_report_csv_to_file(response:, report: 'projection')
  end

  def projection_report_csv
    url = URI(PROJECTION_REPORT_CSV_URL)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    add_request_headers(request:, page: 'projection_report', verb: 'export')
    response = https.request(request)
    write_projection_report_csv_to_file(response)
  end

  # rubocop:disable Metrics/ParameterLists, Metrics/MethodLength
  def orders_report_post(start_date:,
                         end_date:,
                         statuses: nil,
                         tags_any_order: nil,
                         tags_all_order: nil,
                         tags_none_order: nil,
                         tags_any_company: nil,
                         tags_all_company: nil,
                         tags_none_company: nil,
                         tags_any_product: nil,
                         tags_all_product: nil,
                         tags_none_product: nil)
    url = URI(ORDERS_REPORT_URL)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(url)
    add_request_headers(request:, page: 'orders_report', verb: 'post')
    form_hash = orders_report_body(start_date:, end_date:, statuses:)
    encoded_body = URI.encode_www_form(form_hash)
    request_body_encoded = orders_report_body_add_tags(encoded_body:,
                                                       tags_any_order:,
                                                       tags_all_order:,
                                                       tags_none_order:,
                                                       tags_any_company:,
                                                       tags_all_company:,
                                                       tags_none_company:,
                                                       tags_any_product:,
                                                       tags_all_product:,
                                                       tags_none_product:)
    request.body = request_body_encoded
    https.request(request)
  end
  # rubocop:enable Metrics/ParameterLists, Metrics/MethodLength

  def write_orders_report_csv_to_file(response:, line:)
    write_report_csv_to_file(response:, report: "#{line}_orders")
  end

  def orders_report_csv(line:)
    url = URI(ORDERS_REPORT_CSV_URL)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    add_request_headers(request:, page: 'orders_report', verb: 'export')
    response = https.request(request)
    write_orders_report_csv_to_file(response:, line:)
  end

  def product_edit_get(product_id:)
    url = URI("#{PRODUCT_EDIT_URL}/#{product_id}/")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    add_request_headers(request:, page: 'product-edit', verb: 'get')
    https.request(request)
  end

  # NOTE: This method does not work, even in Postman
  def product_edit_post(product_id:, payload_hsh:)
    url = URI("#{PRODUCT_EDIT_URL}/#{product_id}/")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(url)
    add_request_headers(request:, page: 'product-edit', verb: 'post')

    form_data = payload_hsh.to_a
    request.set_form(form_data, 'multipart/form-data')
    puts Rainbow(url).orange
    https.request(request)
  end

  def products_get
    url = URI(PRODUCTS_URL)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    add_request_headers(request:, page: 'products', verb: 'get')
    https.request(request)
  end

  def products_csv(phpsessid: nil)
    url = URI(PRODUCTS_CSV_URL)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    add_request_headers(request:, page: 'products', verb: 'csv')

    # For some bizarre reason I can't use @phpsessid
    if phpsessid.nil?
      puts 'Enter PHPSESSID: '
      phpsessid = $stdin.gets.strip
    end

    request['Cookie'] = "PHPSESSID=#{phpsessid}"
    response = https.request(request)
    write_products_csv_to_file(response:)
  end

  def product_label_get(product_id:)
    url = URI("#{PRODUCT_LABEL_URL}/#{product_id}/")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    add_request_headers(request:, page: 'product-labels', verb: 'get')
    https.request(request)
  end

  def product_label_post(label_div_id:, product_id:, label_list_id:, html:)
    url = URI("#{PRODUCT_LABEL_URL}/#{product_id}/")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(url)
    add_request_headers(request:, page: 'product-labels', verb: 'post')
    form_hash = product_label_body(label_div_id:, label_list_id:, html:)
    encoded_body = [URI.encode_www_form(form_hash), '%0D%0A'].join
    request.body = encoded_body
    puts url
    https.request(request)
  end

  def product_clone_get(product_id:)
    # url = URI("#{PRODUCT_CLONE_URL}/#{product_id}/")
    # https = Net::HTTP.new(url.host, url.port)
    # https.use_ssl = true
    # request = Net::HTTP::Get.new(url)
    # add_request_headers(request:, page: 'product-clone', verb: 'get')
    # https.request(request)

    # HTTParty

    hsh = @allmoxy_constants['product-clone']['request_headers']['get']
    hsh['Cookie'] = "PHPSESSID=#{@phpsessid}"

    res = self.class.get(
      "/catalog/products/clone/#{product_id}/",
      follow_redirects: true,
      headers: hsh
    )

    # new product ID
    res.request.path.to_s.scan(/\d+/).first.to_i
  end

  def product_parts_get(product_id:)
    url = URI("#{PRODUCT_PARTS_URL}/#{product_id}/")
    puts Rainbow("URL: #{url}")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    add_request_headers(request:, page: 'product-parts', verb: 'get')
    https.request(request)
  end

  def product_parts_post(product_id:, payload_hsh:)
    url = URI("#{PRODUCT_PARTS_URL}/#{product_id}/")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(url)
    add_request_headers(request:, page: 'product-parts', verb: 'post')
    form_data = payload_hsh.to_a
    request.set_form(form_data, 'multipart/form-data')
    puts Rainbow(url).orange
    https.request(request)
  end

  def product_attribute_get(product_attribute_id:)
    url = URI("#{PRODUCT_ATTRIBUTE_URL}/#{product_attribute_id}/")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    add_request_headers(request:, page: 'product_attribute', verb: 'get')
    https.request(request)
  end

  def product_attribute_csv_get(product_attribute_id:)
    url = URI("#{PRODUCT_ATTRIBUTE_EXPORT_URL}/#{product_attribute_id}/")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    add_request_headers(request:, page: 'product_attributes', verb: 'get')
    response = https.request(request)
    write_product_attribute_selections_csv_to_file(response:, product_attribute_id:)
  end

  def product_attributes_get
    url = URI(PRODUCT_ATTRIBUTES_URL)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    add_request_headers(request:, page: 'products', verb: 'get')
    https.request(request)
  end

  def product_attributes_csv_get
    url = URI(PRODUCT_ATTRIBUTES_CSV_URL)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    add_request_headers(request:, page: 'products', verb: 'csv')
    https.request(request)
  end

  def order_finish_pricing_get(order_number:)
    uri = "#{ORDER_URL}/#{order_number}/22/"
    url = URI(uri)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    add_request_headers(request:, page: 'order', verb: 'get')
    https.request(request)
  end

  def companies_get
    url = URI(COMPANIES_URL)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    add_request_headers(request:, page: 'companies', verb: 'get')
    https.request(request)
  end

  def order_history_get(order_number:)
    url = URI("#{ORDER_HISTORY_URL}/#{order_number}/")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    add_request_headers(request:, page: 'order-history', verb: 'get')
    https.request(request)
  end

  def status_history_report_post(start_date:, end_date:, group_by: 'export_class', show_only_forward_movements: 1)
    url = URI(STATUS_ORDER_HISTORY_URL)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(url)
    add_request_headers(request:, page: 'status_history_report', verb: 'post')
    form_hash = status_history_report_body(start_date:, end_date:, group_by:, show_only_forward_movements:)
    request.body = URI.encode_www_form(form_hash)
    https.request(request)
  end

  def write_status_history_report_csv_to_file(response)
    write_report_csv_to_file(response:, report: 'status_history')
  end

  def status_history_report_csv
    url = URI(STATUS_ORDER_HISTORY_CSV_URL)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    add_request_headers(request:, page: 'status_history_report', verb: 'export')
    response = https.request(request)
    write_status_history_report_csv_to_file(response)
  end
end
