require "rails_helper"

RSpec.describe OauthSessionsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/oauth_sessions").to route_to("oauth_sessions#index")
    end

    it "routes to #new" do
      expect(get: "/oauth_sessions/new").to route_to("oauth_sessions#new")
    end

    it "routes to #show" do
      expect(get: "/oauth_sessions/1").to route_to("oauth_sessions#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/oauth_sessions/1/edit").to route_to("oauth_sessions#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/oauth_sessions").to route_to("oauth_sessions#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/oauth_sessions/1").to route_to("oauth_sessions#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/oauth_sessions/1").to route_to("oauth_sessions#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/oauth_sessions/1").to route_to("oauth_sessions#destroy", id: "1")
    end
  end
end
