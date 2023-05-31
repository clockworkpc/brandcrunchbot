class AllmoxyApiBeta
  class ProductService < AllmoxyApiBeta
    def products(product_id: nil)
      get_response(path: get_path(__method__, product_id))
    end
  end
end
