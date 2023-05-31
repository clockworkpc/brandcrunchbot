class BrowserService
  class AllmoxyProductReportService < AllmoxyProductService
    def write_product_tags_csv_to_file(csv:)
      filename = "tmp/product_tags_#{DateTime.now.iso8601}.csv"
      f = File.open(filename, 'w')
      f.write(csv)
      f.close
    end

    def generate_product_tags_hash(row:)
      product_name = row[:product_name]
      product_id = row[:id]
      puts Rainbow("Looking up #{product_name}: #{product_id}").blue
      res = @aas.product_edit_get(product_id:)
      doc = Nokogiri::HTML(res.body)
      tags = doc.xpath('//ul[@class="feed"]//li')

      {
        product_id:,
        product_name:,
        tags: tags.to_h { |tag| [tag.text.to_sym, tag['value']] }
      }
    end

    def generate_product_tags_report_csv(hsh_ary:)
      tag_keys = hsh_ary.pluck(:tags).map(&:keys).flatten.sort.uniq
      headers = ['product_id', 'product_name', tag_keys.map(&:to_s)].flatten

      csv = CSV.generate do |new_csv|
        new_csv << headers
        hsh_ary.each do |hsh|
          row = [hsh[:product_id], hsh[:product_name]]
          tag_keys.each { |key| row << !hsh[:tags][key].nil? }
          new_csv << row
        end
      end

      write_product_tags_csv_to_file(csv:)
    end

    def generate_product_tags_report(phpsessid: nil) # rubocop:disable Metrics/MethodLength
      hsh_ary = []
      latest_csv = Utils.latest_csv_in_tmp(str: 'product_tags')
      is_up_to_date = if latest_csv.nil?
                        false
                      else
                        latest_csv_date_string = latest_csv.scan(/\d{4}-\d{2}-\d{2}/).first
                        latest_csv_date = DateTime.parse(latest_csv_date_string)
                        latest_csv_date.today?
                      end

      list_products(phpsessid:) unless is_up_to_date

      Rails.logger.info('Checking the tags for each product in Allmoxy')
      latest_products_list.each do |row|
        hash = generate_product_tags_hash(row:)
        hsh_ary << hash
      end

      generate_product_tags_report_csv(hsh_ary:)

      hsh_ary
    end

    def upload_product_tags_report(spreadsheet_id:, range:, csv_path:)
      gsa = GoogleSheetsApi.new
      Rails.logger.info("Clearing values from spreadsheet: #{spreadsheet_id}")
      gsa.clear_values(spreadsheet_id:, range:)
      Rails.logger.info("Updating values in spreadsheet: #{spreadsheet_id}")
      res = gsa.update_values(spreadsheet_id:, range:, csv_path:)
      Rails.logger.info('Values updated!')
      res
    end

    def refresh_product_tags_report(spreadsheet_id:, phpsessid: nil)
      generate_product_tags_report(phpsessid:)
      range = 'product_tags_report!A1:AZ'
      csv_path = Utils.latest_csv_in_tmp(str: 'product_tags')
      upload_product_tags_report(spreadsheet_id:, range:, csv_path:)
    end
  end
end
