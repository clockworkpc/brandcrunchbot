require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to test the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator. If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails. There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.

RSpec.describe "/product_orders", type: :request do
  
  # This should return the minimal set of attributes required to create a valid
  # ProductOrder. As you add validations to ProductOrder, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    skip("Add a hash of attributes valid for your model")
  }

  let(:invalid_attributes) {
    skip("Add a hash of attributes invalid for your model")
  }

  describe "GET /index" do
    it "renders a successful response" do
      ProductOrder.create! valid_attributes
      get product_orders_url
      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      product_order = ProductOrder.create! valid_attributes
      get product_order_url(product_order)
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    it "renders a successful response" do
      get new_product_order_url
      expect(response).to be_successful
    end
  end

  describe "GET /edit" do
    it "renders a successful response" do
      product_order = ProductOrder.create! valid_attributes
      get edit_product_order_url(product_order)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new ProductOrder" do
        expect {
          post product_orders_url, params: { product_order: valid_attributes }
        }.to change(ProductOrder, :count).by(1)
      end

      it "redirects to the created product_order" do
        post product_orders_url, params: { product_order: valid_attributes }
        expect(response).to redirect_to(product_order_url(ProductOrder.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a new ProductOrder" do
        expect {
          post product_orders_url, params: { product_order: invalid_attributes }
        }.to change(ProductOrder, :count).by(0)
      end

      it "renders a successful response (i.e. to display the 'new' template)" do
        post product_orders_url, params: { product_order: invalid_attributes }
        expect(response).to be_successful
      end
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:new_attributes) {
        skip("Add a hash of attributes valid for your model")
      }

      it "updates the requested product_order" do
        product_order = ProductOrder.create! valid_attributes
        patch product_order_url(product_order), params: { product_order: new_attributes }
        product_order.reload
        skip("Add assertions for updated state")
      end

      it "redirects to the product_order" do
        product_order = ProductOrder.create! valid_attributes
        patch product_order_url(product_order), params: { product_order: new_attributes }
        product_order.reload
        expect(response).to redirect_to(product_order_url(product_order))
      end
    end

    context "with invalid parameters" do
      it "renders a successful response (i.e. to display the 'edit' template)" do
        product_order = ProductOrder.create! valid_attributes
        patch product_order_url(product_order), params: { product_order: invalid_attributes }
        expect(response).to be_successful
      end
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested product_order" do
      product_order = ProductOrder.create! valid_attributes
      expect {
        delete product_order_url(product_order)
      }.to change(ProductOrder, :count).by(-1)
    end

    it "redirects to the product_orders list" do
      product_order = ProductOrder.create! valid_attributes
      delete product_order_url(product_order)
      expect(response).to redirect_to(product_orders_url)
    end
  end
end