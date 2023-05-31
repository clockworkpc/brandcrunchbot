require 'rails_helper'

RSpec.describe "SchedulingServices", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/scheduling_services/index"
      expect(response).to have_http_status(:success)
    end
  end

end
