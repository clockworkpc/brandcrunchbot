require 'rails_helper'

RSpec.describe "product_order_items/new", type: :view do
  before(:each) do
    assign(:product_order_item, ProductOrderItem.new(
      product_order: nil,
      line_number: 1,
      unit_price: "9.99",
      finish_price: "9.99",
      quantity: 1,
      specialty_price: "9.99",
      line_total: "9.99"
    ))
  end

  it "renders new product_order_item form" do
    render

    assert_select "form[action=?][method=?]", product_order_items_path, "post" do

      assert_select "input[name=?]", "product_order_item[product_order_id]"

      assert_select "input[name=?]", "product_order_item[line_number]"

      assert_select "input[name=?]", "product_order_item[unit_price]"

      assert_select "input[name=?]", "product_order_item[finish_price]"

      assert_select "input[name=?]", "product_order_item[quantity]"

      assert_select "input[name=?]", "product_order_item[specialty_price]"

      assert_select "input[name=?]", "product_order_item[line_total]"
    end
  end
end