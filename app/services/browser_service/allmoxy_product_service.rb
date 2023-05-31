class BrowserService
  class AllmoxyProductService < AllmoxyService # rubocop:disable Metrics/ClassLength
    EXPORTER_CODES = JSON.parse(File.read('app/assets/config/allmoxy_exporters.json')).freeze
    def goto_product_part(product_id:)
      get_response = @aas.product_parts_get(product_id:)
      doc = Nokogiri::HTML(get_response.body)
    end

    def update_product_label(product_id:, label_list_id:, html:)
      get_response = @aas.product_label_get(product_id:)
      doc = Nokogiri::HTML(get_response.body)
      label_div_id_string = doc.xpath('//fieldset')
                               .filter_map { |e| e['id'] }
                               .find { |id| id.match?(/label_\d/) }
      label_div_id = label_div_id_string.nil? ? '25' : label_div_id_string.scan(/\d+/).first
      @aas.product_label_post(label_div_id:, product_id:, label_list_id:, html:)
    end

    def convert_part_html_to_payload(fieldset:)
      service = BrowserService::AllmoxyProductPartService.new
      service.convert_part_html_to_payload(fieldset:)
    end

    def product_part_fieldsets(product_id:)
      get_response = @aas.product_parts_get(product_id:)
      doc = Nokogiri::HTML(get_response.body)
      parts_div = doc.xpath('//div[@id="parts"]').first
      parts_div.xpath('.//fieldset[starts-with(@id,"part_")]').select { |e| e['id'].match?(/part_\d+/) }
    end

    def generate_product_parts_hash(fieldsets:)
      hash = {}
      fieldsets.each do |fieldset|
        hsh = convert_part_html_to_payload(fieldset:)
        hsh.each do |k, v|
          hash[k] = v
        end
      end
      hash
    end

    def generate_salvador_product_parts_hash(fieldsets:)
      hash = {}
      fieldsets.each do |fieldset|
        hsh = convert_part_html_to_payload(fieldset:)
        part_ids = hsh.select { |k, v| k.match?('display_name') && v.downcase.match?('salvador') }
                      .keys.map { |k1| k1.scan(/\d+/).first }

        part_ids.each do |part_id|
          display_name = hsh.select { |k, _v| k.match?(part_id) && k.match?('display_name') }
          cutlist_formula = hsh.select { |k, _v| k.match?(part_id) && k.match?('cutlist_formula') }
        end
      end
      hash
    end

    def write_product_payload_to_tmp(product_id:, hsh:)
      f = File.open("tmp/products/product_parts_#{product_id}.txt", 'w')
      f.write("x: y\n")
      hsh.each { |k, v| f.write("#{k}: #{v}\n") }
      f.write('data_end: 1')
      f.close
    end

    def salvador_cutlist_formulae(hsh:)
      salvador_part_ids = hsh
                          .select { |k, v| k.match?('display_name') && v.downcase.match?('salvador') }
                          .keys.map { |k1| k1.scan(/\d+/).first }

      hsh.select do |k, v|
        next if v.nil?

        part_id = k.scan(/\d+/).first
        next unless salvador_part_ids.include?(part_id)

        k.include?('cutlist_formula')
      end
    end

    def salvador_display_names_and_cutlist_formulae(hsh:)
      salvador_part_ids = hsh.select do |k, v|
                            k.match?('display_name') && v.downcase.match?('salvador')
                          end .keys.map { |k1| k1.scan(/\d+/).first }

      hsh.select do |k, v|
        next if v.nil?

        part_id = k.scan(/\d+/).first
        next unless salvador_part_ids.include?(part_id)

        k.include?('cutlist_formula') ||
          k.include?('display_name')
      end
    end

    def salvador_codes_dictionary
      {
        'salvador top rail' => 'TR',
        'salvador bottom rail' => 'BR',
        'salvador left stile' => 'LS',
        'salvador right stile' => 'RS',
        'salvador horiz. mid rail' => 'HR',
        'salvador vert. mid rail' => 'VR'
      }
    end

    def add_code_to_value(display_name:, v:)
      puts Rainbow(display_name).orange
      puts Rainbow(display_name.strip.downcase).blue
      clean_display_name = display_name.strip.downcase
      "#{v},#{salvador_codes_dictionary[clean_display_name]}"
    end

    def restore_salvador_export_formulae(hsh:, sdnacf:)
      extract_part_id = ->(key) { key.scan(/\d+/).first }
      usef = hsh
      dictionary = sdnacf
                   .select { |k, _v| k.include?('display_name') }
                   .to_h { |k1, v1| [extract_part_id.call(k1), v1] }

      salvador_cutlist_formulae = sdnacf.select { |k, _v| k.include?('cutlist_formula') }

      salvador_cutlist_formulae.each do |k, v|
        part_id = extract_part_id.call(k)
        display_name = dictionary[part_id]
        updated_value = add_code_to_value(display_name:, v:)
        usef[k] = updated_value
      end

      usef
    end

    def restore_salvador_export_formulae(hsh:, sdnacf:)
      extract_part_id = ->(key) { key.scan(/\d+/).first }
      usef = hsh
      dictionary = sdnacf
                   .select { |k, _v| k.include?('display_name') }
                   .to_h { |k1, v1| [extract_part_id.call(k1), v1] }

      salvador_cutlist_formulae = sdnacf.select { |k, _v| k.include?('cutlist_formula') }

      salvador_cutlist_formulae.each do |k, v|
        part_id = extract_part_id.call(k)
        display_name = dictionary[part_id]
        updated_value = add_code_to_value(display_name:, v:)
        usef[k] = updated_value
      end

      usef
    end

    def updated_salvador_export_formulae(hsh:, sef:)
      usef = hsh
      sef.each do |k, v|
        next if v.nil?

        usef[k] = v.sub(/{{line_num}}\d/, '{{line_num}}')
      end
      usef
    end

    def convert_to_payload_hash(hsh:, header: true, footer: true)
      payload_hsh = []
      payload_hsh['x'] = 'y' if header

      hsh.each do |k, v|
        v = '' if v.nil?
        payload_hsh[k] = v
      end

      payload_hsh['data_end'] = '1' if footer
      payload_hsh
    end

    def remove_integer_from_salvador_export_formulae(product_id:)
      fieldsets = product_part_fieldsets(product_id:)
      hsh = generate_product_parts_hash(fieldsets:)
      write_product_payload_to_tmp(product_id:, hsh:)
      sef = salvador_export_formulae(hsh:)
      usef = updated_salvador_export_formulae(hsh:, sef:)
      payload_hsh = convert_to_payload_hash(hsh: usef)
      res = @aas.product_parts_post(product_id:, payload_hsh:)
      if res.code.to_i == 302 && res.message.eql?('Found')
        puts Rainbow("Salvador formulae updated for #{product_id}").green
      else
        puts Rainbow("Salvador formulae NOT updated for #{product_id}").red
      end
      res
    end

    def salvador_codes_appended?(product_id:)
      fieldsets = product_part_fieldsets(product_id:)
      hsh = generate_product_parts_hash(fieldsets:)
      scf = salvador_cutlist_formulae(hsh:)
      check = scf.values
                 .filter_map { |v| salvador_codes_dictionary.value?(v[-2..-1]) }
                 .compact.uniq
      check.count == 1 && check.first == true
    end

    def post_appended_salvador_codes(product_id:, payload_hsh:, codes_appended:)
      if codes_appended
        puts Rainbow("Codes already appended for #{product_id}").red
        return
      end

      res = @aas.product_parts_post(product_id:, payload_hsh:)
      if res.code.to_i == 302 && res.message.eql?('Found')
        puts Rainbow("Salvador formulae updated for #{product_id}").green
      else
        puts Rainbow("Salvador formulae NOT updated for #{product_id}").red
      end
      res
    end

    def append_codes_to_salvador_export_formulae(product_id:)
      fieldsets = product_part_fieldsets(product_id:)
      hsh = generate_product_parts_hash(fieldsets:)
      write_product_payload_to_tmp(product_id:, hsh:)
      sdnacf = salvador_display_names_and_cutlist_formulae(hsh:)
      usef = restore_salvador_export_formulae(hsh:, sdnacf:)
      payload_hsh = convert_to_payload_hash(hsh: usef)
      codes_appended = salvador_codes_appended?(product_id:)
      post_appended_salvador_codes(product_id:, payload_hsh:, codes_appended:)
    end

    def salvador_product_ids
      product_ids = latest_products_list_ids
      product_ids.select { |product_id| product_for_salvador?(product_id:) }
    end

    def clone_product(product_id:)
      @aas.product_clone_get(product_id:)
    end

    def list_products(phpsessid: nil)
      @aas.products_get
      @aas.products_csv(phpsessid:)
    end

    def latest_products_list
      CSV.table(Utils.latest_csv_in_tmp(str: 'products'))
    end

    def latest_products_list_ids(sort: true)
      list = latest_products_list. pluck(:id)
      sort ? list.sort : list
    end

    def latest_product_id
      latest_products_list.pluck(:id).max
    end

    def product_for_salvador?(product_id:)
      parts_page = @aas.product_parts_get(product_id:)
      doc = Nokogiri::HTML(parts_page.body)
      res = doc.xpath('//input[starts-with(@value, "Salvador")]').count.positive?
      message = if res
                  Rainbow("Product #{product_id} has Salvador export formulae").green
                else
                  Rainbow("Product #{product_id} has no Salvador export formulae").red
                end

      puts message
      res
    end

    def product_with_finish?(product_id:)
      parts_page = @aas.product_parts_get(product_id:)
      doc = Nokogiri::HTML(parts_page.body)
      res = doc.xpath('//input[starts-with(@value, "Finish")]').count.positive?
      name = doc.xpath('//legend').find { |legend| legend.text.match?('Parts for') }.text.gsub('Parts for ', '')
      message = if res
                  Rainbow("#{name}, #{product_id}, has Finish export formulae").green
                else
                  Rainbow("#{name}, #{product_id}, has no Finish export formulae").red
                end

      puts message
      res
    end

    def product_parts_title(product_id:)
      res = @aas.product_parts_get(product_id:)
      doc = Nokogiri::HTML(res.body)
      title_h1 = doc.xpath('//h1').first
      return if title_h1.nil?

      title_h1.text.delete_prefix('Parts for ')
    end

    def generate_product_exporters_hash(product_ids:)
      product_ids.map do |product_id|
        title = product_parts_title(product_id:)
        fieldsets = product_part_fieldsets(product_id:)
        product_parts_hsh = generate_product_parts_hash(fieldsets:)
        exporter_codes = product_parts_hsh.select { |k0, v0| k0.match?('exporter') && v0 }.values.uniq
        exporters = EXPORTER_CODES.sort_by { |_k, v| v }.to_h { |k0, v0| [v0, exporter_codes.include?(k0)] }
        hsh = { 'product_id' => product_id, 'title' => title }
        exporters.each { |k, v| hsh[k] = v }
        hsh
      end
    end

    def back_up_product_exporters(product_ids:)
      hsh_ary = generate_product_exporters_hash(product_ids:)
      headers = hsh_ary.map(&:keys).flatten.uniq
      spreadsheet_id = Rails.application.credentials[:spreadsheet_id_allmoxy_products]
      gsa = GoogleSheetsApi.new
      range = 'exporters!A1:AZ'
      Rails.logger.info('Clearing values from Product Exporters spreadsheet'.light_cyan)
      gsa.clear_values(spreadsheet_id:, range:)
      Rails.logger.info('Updating values in Product Exporters spreadsheet'.light_cyan)
      gsa.update_values_from_simple_hash_array(spreadsheet_id:, range:, headers:, hsh_ary:)
    end

    # def add_part_to_product(options = {})
    # end

    # TODO
    # def update_part_export_formula(product_id:, part_id:, formula:)
    #   doc = goto_product_part(product_id:)
    # end
  end
end
