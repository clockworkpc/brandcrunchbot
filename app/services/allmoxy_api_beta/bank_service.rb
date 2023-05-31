class AllmoxyApiBeta
  class BankService < AllmoxyApiBeta
    def banks(bank_id: nil)
      get_response(path: get_path(__method__, bank_id))
    end
  end
end
