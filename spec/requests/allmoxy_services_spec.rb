require 'rails_helper'

RSpec.describe "AllmoxyServices", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/allmoxy_services/index"
      expect(response).to have_http_status(:success)
    end
  end

end
