require 'rails_helper'

RSpec.describe "product_order_items/edit", type: :view do
  before(:each) do
    @product_order_item = assign(:product_order_item, ProductOrderItem.create!(
      product_order: nil,
      line_number: 1,
      unit_price: "9.99",
      finish_price: "9.99",
      quantity: 1,
      specialty_price: "9.99",
      line_total: "9.99"
    ))
  end

  it "renders the edit product_order_item form" do
    render

    assert_select "form[action=?][method=?]", product_order_item_path(@product_order_item), "post" do

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
