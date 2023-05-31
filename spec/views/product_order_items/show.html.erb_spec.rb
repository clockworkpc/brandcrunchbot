require 'rails_helper'

RSpec.describe "product_order_items/show", type: :view do
  before(:each) do
    @product_order_item = assign(:product_order_item, ProductOrderItem.create!(
      product_order: nil,
      line_number: 2,
      unit_price: "9.99",
      finish_price: "9.99",
      quantity: 3,
      specialty_price: "9.99",
      line_total: "9.99"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
  end
end
