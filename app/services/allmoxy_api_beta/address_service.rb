class AllmoxyApiBeta
  class AddressService < AllmoxyApiBeta
    def addresses(address_id: nil)
      get_response(path: get_path(__method__, address_id))
    end
  end
end
