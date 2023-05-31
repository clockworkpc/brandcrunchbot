class AllmoxyApiBeta
  class TagService < AllmoxyApiBeta
    def tags(tag_id: nil)
      get_response(path: get_path(__method__, tag_id))
    end
  end
end
