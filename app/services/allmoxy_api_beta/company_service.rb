class AllmoxyApiBeta
  class CompanyService < AllmoxyApiBeta
    def companies(company_id: nil)
      get_response(path: get_path(__method__, company_id))
    end
  end
end
