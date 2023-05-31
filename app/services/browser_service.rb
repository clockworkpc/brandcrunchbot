require 'rainbow'
require 'colorize'
require 'csv'

# rubocop:disable Metrics/ClassLength
class BrowserService
  attr_reader :browser, :s, :h
  ALLMOXY_CONSTANTS = JSON.parse(File.read('app/assets/config/allmoxy_constants.json')).freeze
  def initialize(browser)
    Watir.default_timeout = 2
    @browser = browser
    @s = Browser::Pages::SignIn.new(@browser)
    @h = Browser::Pages::Home.new(@browser)
    @rls = Browser::Pages::ReportsLeftSidebar.new(@browser)
  end

  # rubocop:disable Metrics/MethodLength
  def finish_factors
    [
      'Clear',
      'Stain & Seal',
      'Stain & Clear',
      'Paint',
      'Primer',
      'Primer & Caulk',
      'Clear & Glaze',
      'Paint & Clear',
      'Paint & Caulk',
      'Primer & Applied Molding',
      'Paint & Caulk & Clear',
      'Paint with Applied Molding',
      'Stain & Glaze',
      'Paint & Clear with Applied Molding',
      'Paint & Glaze'
    ]
  end
  # rubocop:enable Metrics/MethodLength

  def sign_in
    pd_url = 'https://panhandledooranddrawer.allmoxy.com/login'
    @browser.goto(pd_url)
    @s.username_text_field.set(Rails.application.credentials[:allmoxy_username])
    @s.password_input.set(Rails.application.credentials[:allmoxy_password])
    @s.login_button.click
  end

  def load_order(order_number)
    @browser.goto("https://panhandledooranddrawer.allmoxy.com/orders/quote/#{order_number}")
  end

  def load_product(product_number)
    @browser.goto("https://panhandledooranddrawer.allmoxy.com/catalog/products/parts/#{product_number}")
  end

  def goto_finish_price(order_number)
    @browser.goto("https://panhandledooranddrawer.allmoxy.com/orders/output/#{order_number}/22/")
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def extract_finish_pricing(output_group, order_number)
    (1...(output_group.children.count)).map do |n|
      text = output_group.children[n].text
      line = text.sub("\nFinish\nPrice", '').split("\n")
      next if text.match?('Total Items')
      next if text.match?('Total Item')
      next if text.empty?

      p output_group.children[n].text
      p line

      begin
        order = order_number.strip
        id = line[0].scan(/\d\s\d+/).first.split.join
        qty = line[0].split[2].to_i
        finish_price = line[1].to_f
        item_price = line[2].delete('$').split[0].to_f
        total_price = line[2].delete('$').split[1].to_f
      rescue StandardError
        order = order_number.strip
        id = 'nil'
        qty = 'nil'
        finish_price = 'nil'
        item_price = 'nil'
        total_price = 'nil'
      end

      {
        order:,
        id:,
        qty:,
        finish_price:,
        item_price:,
        total_price:
      }
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def collect_finish_prices(order_number)
    ary = []
    goto_finish_price(order_number)
    puts "output groups: #{@browser.tables(id: /output_group/).count}"
    output_groups = @browser.tables(id: /output_group/)
    output_groups.each do |output_group|
      p output_group
      output_group.click
      hsh = extract_finish_pricing(output_group, order_number)
      ary << hsh
    end
    ary.flatten.compact
  end

  def add_finish_prices_to_csv(order_number_ary)
    headers = %w[order id qty finish_price item_price total_price]
    csv_path = "tmp/finish_prices_#{DateTime.now.strftime('%Y%m%d_%H%M%S')}.csv"

    # rows = order_number_ary.map do |order_number|
    #   puts Rainbow("Collecting numbers for #{order_number}").orange
    #   collect_finish_prices(order_number)
    # end.flatten.compact

    CSV.open(csv_path, 'wb') do |csv|
      csv << headers
      order_number_ary.each do |order_number|
        puts Rainbow("Collecting numbers for #{order_number}").orange
        rows = collect_finish_prices(order_number)
        rows.each do |row|
          puts Rainbow(row.values).green
          csv << row.values
        end
      end

      # rows.each do |row|
      #   csv << row.values
      #   puts Rainbow(row.values).green
      # end
    end

    # f = File.open(csv_path, 'w+')
    # f.write(finish_orders)
    # f.close
  end

  def find_product_part_id(display_name)
    product_part = @browser.input(value: display_name)
    product_part.id.scan(/\d+/).first
  end

  def unfold_product_part(display_name)
    part_id_str = find_product_part_id(display_name)
    part_link = @browser.link(onclick: /#{part_id_str}/, class: nil)
    part_link.focus
    part_link.hover
    part_link.click
  end

  def order_finish
    @browser.options(selected: '')
            .select { |opt| finish_factors.include?(opt.text) }
            .map(&:text)
            .first
  end

  def find_order_finish(str)
    order_number = str.to_s
    load_order(order_number)
    { order: order_number, finish_type: order_finish }
  end

  def find_orders_finish(ary)
    ary.map { |str| find_order_finish(str) }
  end

  def display_orders_finish(hsh_ary)
    hsh_ary.each { |hsh| puts "#{hsh[:order]},#{hsh[:finish_type]}" }
  end

  def sample_orders
    %w[ 77707
        58404
        58404]
  end

  def goto_product_parts(product_id)
    @browser.goto("https://panhandledooranddrawer.allmoxy.com/catalog/products/parts/#{product_id}/")
  end

  def finish_part_present?
    @browser.inputs(type: 'text', value: 'Finish').count.positive?
  end

  def finish_part
    @browser.input(type: 'text', value: 'Finish')
  end

  def finish_part_id
    finish_part.attributes[:id].scan(/\d{6}/).first
  end

  def unfold_finish_part
    finish_part.focus
    toggle = @browser.fieldset(id: "part_#{finish_part_id}").div(style: 'float: right;').as(class: 'delete_link').first
    toggle.focus
    toggle.click
  end

  # def update_finish_part_export_formula
  #   return unless finish_part.present?

  #   unfold_finish_part

  #   textarea = @browser.textarea(id: "parts[#{finish_part_id}][cutlist_formula]")
  #   textarea.focus
  #   source_text = textarea.text
  #   html_var = '{{line_price}}'

  #   return if source_text.include?(html_var)

  #   new_text = [source_text, html_var].join(',')
  #   textarea.set(new_text)
  # end

  def save_changes
    @browser.i(class: 'fa fa-save').click
  end

  def update_finish_part_export_formula(product_id) # rubocop:disable Metrics/MethodLength
    puts Rainbow("Updating Product ID: #{product_id}").orange
    goto_product_parts(product_id)

    unless finish_part_present?
      puts Rainbow('No finish part present').red
      return
    end

    puts Rainbow('Finish Part found').blue
    unfold_finish_part

    textarea = @browser.textarea(id: "parts[#{finish_part_id}][cutlist_formula]")
    textarea.focus
    source_text = textarea.text
    html_var = '{{line_price}}'

    if source_text.include?(html_var)
      puts Rainbow('{{line_price}} variable already present').red
      return
    else
      puts Rainbow('Adding {{line_price}} variable').green
    end

    new_text = [source_text, html_var].join(',')
    textarea.set(new_text)
  end

  def update_finish_parts_export_formula(product_id_ary)
    product_id_ary.each do |product_id|
      update_finish_part_export_formula(product_id)

      puts 'Save changes?'
      res = gets.strip.to_i
      next unless res == 1

      save_changes
    end
  end
end
# rubocop:enable Metrics/ClassLength
