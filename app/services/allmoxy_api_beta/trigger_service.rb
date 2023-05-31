class AllmoxyApiBeta
  class TriggerService < AllmoxyApiBeta
    def triggers(trigger_id: nil)
      get_response(path: get_path(__method__, trigger_id))
    end
  end
end
