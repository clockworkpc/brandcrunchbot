class AllmoxyApiBeta
  class OrderProductService < AllmoxyApiBeta
    def order_products(op_id: nil)
      method = __method__.to_s.tr('_', '-')
      get_response(path: get_path(method, op_id))
    end
  end
end
