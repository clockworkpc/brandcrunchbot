class AllmoxyApiBeta
  class OrderStatusHistoryService < AllmoxyApiBeta
    def order_status_history(osh_id: nil)
      method = __method__.to_s.tr('_', '-')
      get_response(path: get_path(method, osh_id))
    end
  end
end
