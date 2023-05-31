class BrowserService
  class AllmoxyProductAttributeService < AllmoxyService
    def initialize(browser)
      super
      @gda = GoogleDriveApi.new
      @gsa = GoogleSheetsApi.new
    end

    def parse_product_attribute_html(get:, product_attribute_id:)
      hsh = { product_attribute: { label: 'Product Attribute ID', value: product_attribute_id } }

      doc = Nokogiri::HTML(get.body)
      attribute_form = doc.xpath('//form[@id="attribute_form"]').first

      header = attribute_form.xpath('./h1').first
      formula_name = doc.xpath('//div[@class="row"]').find { |div| div.text.match?('Formula Name') }
      attribute_type = doc.xpath('//div[@class="row"]').find { |div| div.text.match?('Attribute Type') }
      comments = doc.xpath('//textarea[@id="attribute[comment]"]').first
      order_page_width = doc.xpath('//input[@id="attribute[width]"]').first
      output_page_width = doc.xpath('//input[@id="attribute[output_width]"]').first
      l_margin = doc.xpath('//input[@id="attribute[l_margin]"]').first
      r_margin = doc.xpath('//input[@id="attribute[r_margin]"]').first
      text_alignment = doc.xpath('//select[@id="attribute[align]"]').first
      text_alignment_selected = text_alignment.children.find { |child| child.attributes['selected'] }
      new_row = doc.xpath('//input[@id="attribute[new_row]"]').first
      visibility = doc.xpath('//select[@id="attribute[hidden]"]').first
      visibility_selected = visibility.xpath('./option[@selected]').first if visibility
      associate = doc.xpath('//input[@id="attribute[associate]"]').first
      associate_checked = !associate.attributes['checked'].nil? if associate
      is_presettable = doc.xpath('//input[@id="attribute[is_presettable]"]').first
      is_presettable_checked = !is_presettable.attributes['checked'].nil? if is_presettable
      preset_use_default = doc.xpath('//input[@id="attribute[preset_use_default]"]').first if is_presettable_checked
      preset_use_default_checked = !preset_use_default.attributes['checked'].nil? if preset_use_default
      preset_order = doc.xpath('//input[@id="attribute[preset_order]"]').first if is_presettable_checked
      output_pages_checkboxes = doc.xpath('//input[starts-with(@id, "attribute[lists]")]')
      output_pages = output_pages_checkboxes.map do |e|
        key = e.attributes['id'].value
        label = e.parent.xpath('./i').first.text
        checked = e.attributes['checked']
        value = !checked.nil?
        { key:, label:, value: }
      end

      hsh['attribute[display_name]'] = { label: 'Display Name', value: header.text }
      hsh['formula_name'] = { label: 'Formula Name', value: formula_name.text.split.last }
      hsh['attribute[type]'] = { label: 'Attribute Type', value: attribute_type.text.split.last }
      hsh['attribute[comment]'] = { label: 'Comments', value: comments.text }
      hsh['attribute[width]'] = { label: 'Order Page Width', value: order_page_width.attributes['value'].text }
      hsh['attribute[output_width]'] = { label: 'Output Page Width', value: output_page_width.attributes['value'].text }
      hsh['attribute[l_margin]'] = { label: 'Padding Left', value: l_margin.attributes['value'].text }
      hsh['attribute[r_margin]'] = { label: 'Padding Right', value: r_margin.attributes['value'].text }
      hsh['attribute[align]'] = { label: 'Text Alignment', value: text_alignment_selected.text }
      hsh['attribute[new_row]'] = { label: 'New Row', value: new_row.attributes['value'].text }

      hsh['attribute[hidden]'] = {
        label: 'Order Page Visibility',
        value: (visibility_selected.text if visibility_selected)
      }

      hsh['attribute[associate]'] = { label: 'Associate With Supplies', value: associate_checked ? 'on' : nil }
      hsh['attribute[is_presettable]'] = { label: 'Is A Preset', value: is_presettable_checked ? '1' : nil }
      hsh['attribute[preset_use_default]'] = {
        label: 'Set Attribute Default In Preset',
        value: (if preset_use_default
                  preset_use_default_checked ? '1' : nil
                end)
      }

      hsh['attribute[preset_order]'] = {
        label: 'Preset Order',
        value: (preset_order.attributes['value'].text if preset_use_default && preset_use_default_checked)
      }

      if preset_use_default && preset_use_default_checked
        { label: 'Preset Order', value: preset_order.attributes['value'].text }
      end

      output_pages.each do |output_page|
        hsh[output_page[:key]] = {
          label: "Show on #{output_page[:label]}",
          value: output_page[:value] || false
        }
      end

      hsh
    end

    def write_product_attributes_hash_array_to_csv(hsh_ary:)
      filename = "tmp/product_attributes_#{DateTime.now.iso8601}.csv"
      f = File.open(filename, 'w')
      headers = hsh_ary.first.values.pluck(:label)
      f.write("#{headers}\n")

      hsh_ary.each do |hsh|
        values = hsh.values.join('|')
        f.write("#{values}\n")
      end

      f.close
    end

    def product_attribute_hash(product_attribute_id:)
      get = @aas.product_attribute_get(product_attribute_id:)
      parse_product_attribute_html(get:, product_attribute_id:)
    end

    def product_attribute_selectors_to_csv(product_attribute_id:)
      @aas.product_attribute_csv_get(product_attribute_id:)
      Utils.latest_product_attribute_selection
    end

    def back_up_product_attribute_details(product_attribute_ids:)
      range = 'main!A1:BJ'
      spreadsheet_id = Rails.application.credentials[:spreadsheet_id_allmoxy_product_attributes]
      @gsa = GoogleSheetsApi.new

      hsh_ary = product_attribute_ids.map do |product_attribute_id|
        puts Rainbow("Downloading HTML for Product Attribute #{product_attribute_id}").orange
        product_attribute_hash(product_attribute_id:)
      end

      headers = hsh_ary
                .filter_map(&:values)
                .compact.flatten
                .pluck(:label)
                .uniq

      Rails.logger.info('Clearing values from Product Attributes spreadsheet'.light_cyan)
      @gsa.clear_values(spreadsheet_id:, range:)
      Rails.logger.info('Updating values in Product Attributes spreadsheet'.light_cyan)
      @gsa.update_values_from_hash(spreadsheet_id:, range:, headers:, hsh_ary:)
    end

    def back_up_product_attribute_selections(product_attribute_ids:)
      product_attribute_csv_paths = product_attribute_ids.map do |product_attribute_id|
        puts Rainbow("Downloading CSV for Product Attribute #{product_attribute_id}").orange
        product_attribute_selectors_to_csv(product_attribute_id:)
      end

      parent_folder_id = '1X3wIJupUoyifH61IE90Tnz3ae1QNP0FV'
      folder_path = Utils.latest_product_attribute_selection_directory
      team_drive_id = '0AOjzUAFRsFyVUk9PVA'
      @gda = GoogleDriveApi.new

      @gda.upload_folder(parent_folder_id:, folder_path:, team_drive_id:, scan_int: nil)
    end

    def back_up_product_attributes(product_attribute_ids:)
      back_up_product_attribute_details(product_attribute_ids:)
      back_up_product_attribute_selections(product_attribute_ids:)
    end

    def all_product_attributes
      res = @aas.product_attributes_csv_get
      CSV.parse(res.body, headers: true)
    end

    def all_product_attribute_ids
      csv = all_product_attributes
      csv.filter_map { |row| row['ID'].to_i }.uniq.sort
    end
  end
end
