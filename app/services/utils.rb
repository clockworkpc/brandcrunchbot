class Utils # rubocop:disable Metrics/ClassLength
  def self.date_string(month:, day:, year: DateTime.now.year)
    octal = ->(int) { format('%02d', int) }
    "#{year}-#{octal.call(month)}-#{octal.call(day)}"
  end

  def self.first_day_two_months_ago(month: nil, day: nil, year: nil)
    date = DateTime.parse("#{year}-#{month}-#{day}") unless month.nil? || day.nil? || year.nil?

    if date
      month = date.months_ago(2).month
      day = date.months_ago(2).day
      year = date.months_ago(2).year
    else
      two_months_ago = DateTime.now.months_ago(2)
      month = two_months_ago.month
      day = 1
      year = two_months_ago.year
    end

    date_string(month:, day:, year:)
  end

  def self.last_day_two_months_hence(month: nil, day: nil, year: nil)
    date = DateTime.parse("#{year}-#{month}-#{day}") unless month.nil? || day.nil? || year.nil?

    if date
      month = date.months_since(2).month
      day = date.months_since(2).day
      year = date.months_since(2).year
    else
      two_months_since = DateTime.now.months_since(2)
      month = two_months_since.month
      day = two_months_since.end_of_month.day
      year = two_months_since.year
    end

    date_string(month:, day:, year:)
  end

  def self.latest_csv_in_downloads
    Dir.glob("#{DOWNLOADS_FOLDER}/**.csv").max_by { |f| File.mtime(f) }
  end

  def self.latest_csv_in_tmp(str: nil)
    Dir.glob("#{Rails.root.join("tmp/#{str}**.csv")}").max_by { |f| File.mtime(f) }
  end

  def self.csv_up_to_date?(str:)
    file = Utils.latest_csv_in_tmp(str:)
    date = file.scan(/\d{4}-\d{2}-\d{2}/).first
    DateTime.parse(date).today?
  end

  def self.latest_product_attribute_selection_directory
    Dir.glob("#{Rails.root.join('tmp/product_attributes/product_attributes**')}")
       .select { |f| File.directory?(f) }
       .max_by { |dir| File.mtime(dir) }
  end

  def self.latest_product_attribute_selection
    Dir.glob("#{Utils.latest_product_attribute_selection_directory}/**.csv")
       .max_by { |f| File.mtime(f) }
  end

  def self.allmoxy_product_hash
    hsh = {}
    ALLMOXY_PRODUCTS.each do |row|
      hsh[row[:product_name]] = row[:url]
    end
  end

  def self.to_bool(str)
    return unless str.is_a?(String)

    str = str.downcase

    return unless str.match?(/true|false/)

    str.match?('true')
  end

  def self.read_booleans_from_csv(csv_path)
    hsh = {}
    doc = CSV.table(csv_path)
    tags = doc.headers.reject { |n| n == :product }

    doc.each do |row|
      values = tags.index_with { |tag| to_bool(row[tag]) }
      hsh[row[:product]] = values
    end

    hsh
  end

  def self.read_true_booleans_from_csv(csv_path)
    hsh = {}
    hsh1 = read_booleans_from_csv(csv_path).select { |_k, v| v.flatten.uniq.include?(true) }
    ary = hsh1.map { |k, v| { k => v.select { |_k1, v1| v1 }.keys.map(&:to_s) } }
    ary.each do |h2|
      hsh[h2.keys.first] = h2.values.flatten
    end
    hsh
  end

  def self.notify_send(str, sound_path = nil)
    sound = if sound_path.nil?
              'app/assets/sounds/mixkit-elevator-tone-2863.wav'
            elsif sound_path.eql?(:coin)
              'app/assets/sounds/smw_coin.wav'
            elsif sound_path.eql?(:complete)
              'app/assets/sounds/smw_course_clear.wav'
            end

    puts Rainbow(str).orange
    return if Rails.env.match?(/production|test/)

    # system("notify-send '#{str}' && mpv '#{sound}'")
    system("notify-send '#{str}'")
  end

  def self.simple_datestamp
    DateTime.now.strftime('%Y-%m-%d')
  end

  def self.list_files_without_duplicates(path:, scan_int:)
    files = Dir.glob("#{path}/**")

    refined = files.map do |f0|
      scan = f0.scan(/[a-z0-9-]+/)[scan_int]
      similar = files.grep(/#{scan}/)
      similar.max_by { |f1| File.mtime(f1) }
    end

    refined.uniq
  end

  def self.watir_browser(headless: true)
    if Rails.env.eql?('production')
      Selenium::WebDriver::Chrome::Service.driver_path = '/app/.chromedriver/bin/chromedriver'
      chrome_bin_path = ENV.fetch('GOOGLE_CHROME_SHIM', nil)
    end

    options = Selenium::WebDriver::Chrome::Options.new(
      args: [
        'no-sandbox',
        'window-size=1200x600',
        'disable-gpu'
      ],
      prefs: {
        download: {
          prompt_for_download: false,
          default_directory: Rails.root.join('tmp').to_s
        }
      }
    )

    options.binary = chrome_bin_path if chrome_bin_path
    options.add_argument '--headless' if headless
    options.add_argument('--disable-dev-shm-usage') if headless
    # options.add_argument '--no-sandbox'
    # options.add_argument '--window-size=1200x600'
    # options.add_argument '--disable-gpu'

    Watir::Browser.new(:chrome, options:)
  end

  def self.finish_price_percentage(total_price:, finish_price_total:)
    total_price_float = total_price.to_f
    finish_price_total_float = finish_price_total.to_f
    no_price = total_price_float.zero?

    if no_price
      100
    else
      (finish_price_total_float / total_price_float).to_f * 100
    end
  end

  def self.create_orders_hash_array(csv:)
    ary = []
    csv.each do |row|
      order_number = row[:order]
      order_hsh = ary.find { |n| n[:order][:order_number] == order_number }

      order_details_hsh = {
        order_number: row[:order],
        company_number: row[:company],
        company_name: row[:company_name],
        order_name: row[:order_name],
        total: row[:total],
        ship_date: row[:ship_date]
      }

      product_order_hsh = {
        product_number: row[:product],
        product_name: row[:product_name],
        qty: row[:qty],
        line_subtotal: row[:line_subtotal]
      }

      if order_hsh
        order_hsh[:product_orders] << product_order_hsh
      else
        ary << {
          order: order_details_hsh,
          product_orders: [product_order_hsh]
        }
      end
    end
    ary
  end

  def self.assign_attr(objekt, attr, value)
    return objekt if objekt.send(attr).eql?(value)

    objekt.assign_attributes(attr.to_sym => value)
    objekt
  end

  def self.force_utf8_encoding(str)
    str.encode(Encoding.find('UTF-8'), invalid: :replace, undef: :replace, replace: '')
  end

  def self.working_days_to_date(gsa:, input_date: Time.zone.today.iso8601)
    start_date = Date.new(Time.zone.today.year, 1, 1)
    end_date = Date.parse(input_date)
    key = :spreadsheet_id_production_calendar
    spreadsheet_id = Rails.application.credentials[key]
    range = 'master!F2:F'
    response = gsa.get_spreadsheet_values(spreadsheet_id:, range:)
    response.values.flatten
            .select { |str| Time.zone.today >= Date.parse(str) }
  end

  def self.this_week
    today = Date.current
    monday = today.monday? ? today.iso8601 : today.prev_occurring(:monday).iso8601
    sunday = today.sunday? ? today.iso8601 : today.next_occurring(:sunday).iso8601
    {
      start_date: monday,
      end_date: sunday
    }
  end

  def self.start_dates_this_year
    days = (Date.parse('2023-01-01')..Date.parse('2023-12-31')).to_a
    days.select(&:monday?)
  end

  def self.start_dates_to_date
    Utils.start_dates_this_year.select { |d| d <= Date.current }
  end

  def self.extract_domain_name_from_scheduled_job(job)
    job_wrapper = YAML.safe_load(job.handler,
                                 permitted_classes: [ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper])

    job_data = job_wrapper.job_data
    auction_gid = job_data['arguments'].first['_aj_globalid']

    auction = GlobalID::Locator.locate(auction_gid)
    auction.domain_name
  end

  def self.list_scheduled_jobs
    jobs = Delayed::Job.all.map do |job|
      {
        domain_name: Utils.extract_domain_name_from_scheduled_job(job),
        run_at: job.run_at
      }
    end
    jobs.sort_by { |x| x[:run_at] }
  end

  def self.convert_to_utc(datetime_str:)
    time_without_tz = datetime_str.gsub(/\s*\([A-Z]+\)\s*/, '')
    parsed_time = Time.strptime(time_without_tz, '%m/%d/%Y %I:%M %p')
    Rails.logger.info("parsed time #{parsed_time}".red)
    # TODO: Add 7 hours during PDT and 8 hours during PST
    final_time = parsed_time + (8 * 3600)
    utc_time = final_time.utc
    Rails.logger.info("UTC time #{utc_time}".red)
    utc_time
  end

  def self.testdjs
    Rails.logger.info(Time.now.utc)
    Rails.logger.info(Delayed::Job.count)
    djs = DummyJobScheduler.new
    Delayed::Job.order(created_at: :desc).first
    djs.call
    my_job = Delayed::Job.order(created_at: :desc).first
    Rails.logger.info(my_job)
    Rails.logger.info(Time.now.utc)
    Rails.logger.info(Delayed::Job.count)

    start_time = Time.now

    while Time.now - start_time < 10
      # Your loop code here
      Rails.logger.info(Delayed::Job.count)
      sleep 1
    end
    Rails.logger.info(Time.now.utc)
  end
end
