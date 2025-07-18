require 'rails_helper'

RSpec.describe "Domains", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/domains/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /search" do
    it "returns http success" do
      get "/domains/search"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /results" do
    it "returns http success" do
      get "/domains/results"
      expect(response).to have_http_status(:success)
    end
  end

end
