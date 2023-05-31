require 'rails_helper'

RSpec.describe "product_order_items/index", type: :view do
  before(:each) do
    assign(:product_order_items, [
      ProductOrderItem.create!(
        product_order: nil,
        line_number: 2,
        unit_price: "9.99",
        finish_price: "9.99",
        quantity: 3,
        specialty_price: "9.99",
        line_total: "9.99"
      ),
      ProductOrderItem.create!(
        product_order: nil,
        line_number: 2,
        unit_price: "9.99",
        finish_price: "9.99",
        quantity: 3,
        specialty_price: "9.99",
        line_total: "9.99"
      )
    ])
  end

  it "renders a list of product_order_items" do
    render
    assert_select "tr>td", text: nil.to_s, count: 2
    assert_select "tr>td", text: 2.to_s, count: 2
    assert_select "tr>td", text: "9.99".to_s, count: 2
    assert_select "tr>td", text: "9.99".to_s, count: 2
    assert_select "tr>td", text: 3.to_s, count: 2
    assert_select "tr>td", text: "9.99".to_s, count: 2
    assert_select "tr>td", text: "9.99".to_s, count: 2
  end
end
