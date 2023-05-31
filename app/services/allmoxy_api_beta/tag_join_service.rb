class AllmoxyApiBeta
  class TagJoinService < AllmoxyApiBeta
    def tags_join(tj_id: nil)
      endpoint_path = endpoint_path(__method__)
      get_response(path: get_path(endpoint_path, tj_id))
    end
  end
end
