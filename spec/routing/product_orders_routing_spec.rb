require "rails_helper"

RSpec.describe ProductOrdersController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/product_orders").to route_to("product_orders#index")
    end

    it "routes to #new" do
      expect(get: "/product_orders/new").to route_to("product_orders#new")
    end

    it "routes to #show" do
      expect(get: "/product_orders/1").to route_to("product_orders#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/product_orders/1/edit").to route_to("product_orders#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/product_orders").to route_to("product_orders#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/product_orders/1").to route_to("product_orders#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/product_orders/1").to route_to("product_orders#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/product_orders/1").to route_to("product_orders#destroy", id: "1")
    end
  end
end
