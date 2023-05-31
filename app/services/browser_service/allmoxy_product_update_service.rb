class BrowserService
  class AllmoxyProductUpdateService < AllmoxyProductService
    def update_product_label(label_list_id:, html:)
      @aas.product_label_post(label_list_id:, html:)
    end

    def prepare_tags_payload(product_id:, tags:)
      get_res = @aas.product_edit_get(product_id:)
      doc = Nokogiri::HTML(get_res.body)
      xpath_str = '//div[@class="tag_search_and_cloud "]/div[@class="multi_select"]//li'
      current_tags = doc.xpath(xpath_str)
      current_tag_text_ary = current_tags.map(&:text)

      tag_hsh_ary = current_tags.map do |t|
        { 'value' => t['value'], 'caption' => t.text }
      end

      tags.each do |tag|
        next if current_tag_text_ary.include?(tag)

        value = ALLMOXY_CONSTANTS['orders_report']['tags']
                .find { |hsh| hsh['caption'].eql?(tag) }['value']

        tag_hsh = { 'value' => value, 'caption' => tag }
        tag_hsh_ary << tag_hsh
      end

      tag_hsh_ary
    end

    def convert_tags_to_payload_hash(tag_hsh_ary:)
      payload_hsh = {}
      payload_hsh['tags'] = tag_hsh_ary
      payload_hsh['data_end'] = '1'
      payload_hsh
    end

    def append_product_tags(product_id:, tags:)
      tag_hsh_ary = prepare_tags_payload(product_id:, tags:)
      payload_hsh = convert_tags_to_payload_hash(tag_hsh_ary:)
      @aas.product_edit_post(product_id:, payload_hsh:)
      # GET current_product_tags
      # for each tag, check whether current_product_tags.include?(tag)
      # if it does, next
      # else append to
    end
  end
end
