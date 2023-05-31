class AllmoxyApiBeta
  class ContactService < AllmoxyApiBeta
    def contacts(contact_id: nil)
      get_response(path: get_path(__method__, contact_id))
    end
  end
end
