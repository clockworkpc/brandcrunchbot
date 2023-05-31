class BrowserService
  class AllmoxyProductPartService # rubocop:disable Metrics/ClassLength
    def standard_elements
      [
        'a',
        'div',
        'fieldset',
        'i',
        'input[@type="text"]',
        'input[@type="checkbox"][@checked]',
        'input[@type="hidden"]'
      ]
    end

    def xpath(fieldset:, element:)
      fieldset.xpath(".//#{element}")
              .select { |t0| t0['id'].match?(/parts\[\d+\]/) }
              .reject { |t1| t1['value'].nil? }
    end

    def xpath_standard(fieldset:, hsh:, element:, key: 'id', value: 'value')
      add_to_hash = ->(e) { hsh[e[key]] = e[value] }

      begin
        xpath(fieldset:, element:).each { |e| add_to_hash.call(e) }
      rescue NoMethodError
        "No relevant #{element}.pluralize"
      end

      hsh
    end

    def xpath_selected_options_generic(fieldset:, hsh:)
      xpath(fieldset:, element: 'option[@selected]').each do |option|
        id = option.parent['id']
        value = option['value']
        hsh[id] = value
      end
    rescue NoMethodError
      'No relevant selected options'
    end

    def fieldset_id(fieldset:)
      fieldset['id'].scan(/\d+/).first
    end

    def xpath_selected_options(fieldset:, hsh:, name:)
      fieldset_id = fieldset_id(fieldset:)
      parent = fieldset.xpath(".//select[@id='parts[#{fieldset_id}][#{name}]']").first
      selected_option = parent.xpath('.//option[@selected]').first
      named_option = selected_option['value'] if selected_option
      hsh[parent['id']] = named_option
    end

    def xpath_output_pages(fieldset:, hsh:)
      fieldset_id = fieldset_id(fieldset:)

      begin
        xpath_str = ".//input[@type='checkbox'][@name='parts[#{fieldset_id}][plists][]'][@checked]"
        fieldset.xpath(xpath_str).each do |checkbox|
          hsh[checkbox['name']] = checkbox['value']
        end
      rescue NoMethodError
        'No relevant output page options'
      end
    end

    def xpath_supplies_links(fieldset:, hsh:)
      fieldset_id = fieldset_id(fieldset:)
      supplies_links = fieldset.xpath(".//select[starts-with(@id,'parts[#{fieldset_id}][supplies]')]").select do |f|
        f['id'].match?('[link]')
      end
      supplies_links.each do |supplies_link|
        selected_option = supplies_link.xpath('.//option[@selected]').first
        supplies_option = selected_option['value'] if selected_option
        hsh[supplies_link['id']] = supplies_option
      end
    end

    def xpath_supplies_locations(fieldset:, hsh:)
      fieldset_id = fieldset_id(fieldset:)
      supplies_xpath_str = ".//select[starts-with(@name,'parts[#{fieldset_id}][supplies]')]"
      supplies_locations = fieldset.xpath(supplies_xpath_str).select { |fs| fs['name'].match?('location') }
      supplies_locations.each do |supplies_location|
        selected_option = supplies_location.xpath('.//option[@selected]').first
        supplies_option = selected_option['value'] if selected_option
        hsh[supplies_location['name']] = supplies_option
      end
    end

    def xpath_supplies_items(fieldset:, hsh:)
      fieldset_id = fieldset_id(fieldset:)
      supplies_xpath_str = ".//select[starts-with(@name,'parts[#{fieldset_id}][supplies]')]"
      supplies_items = fieldset.xpath(supplies_xpath_str).select { |fs| fs['name'].match?('item_id') }
      supplies_items.each do |supplies_item|
        selected_option = supplies_item.xpath('.//option[@selected]').first
        next if selected_option.nil?

        supplies_option = selected_option['value'] if selected_option
        hsh[supplies_item['name']] = supplies_option
      end
    end

    def xpath_textareas(fieldset:, hsh:)
      fieldset_id = fieldset_id(fieldset:)
      textareas = fieldset.xpath('.//textarea').select { |t0| t0['id'].match?(fieldset_id) }
      textareas.each do |textarea|
        key = if textarea['id'].match?('supplies')
                textarea['id'].sub('supplies', 'parts')
              else
                textarea['id']
              end

        hsh[key] = textarea.text.gsub("\r\n", ' ').gsub('  ', ' ').gsub(' )', ')').gsub('( ', '(')
      end
    rescue NoMethodError
      puts 'No relevant textarea'
    end

    def convert_part_html_to_payload(fieldset:)
      hsh = {}
      standard_elements.each { |element| xpath_standard(fieldset:, hsh:, element:) }
      xpath_selected_options_generic(fieldset:, hsh:)
      xpath_selected_options(fieldset:, hsh:, name: 'exporter')
      xpath_selected_options(fieldset:, hsh:, name: 'precision')
      xpath_output_pages(fieldset:, hsh:)
      xpath_supplies_links(fieldset:, hsh:)
      xpath_supplies_locations(fieldset:, hsh:)
      xpath_supplies_items(fieldset:, hsh:)
      xpath_textareas(fieldset:, hsh:)

      hsh.sort.to_h
    end
  end
end
