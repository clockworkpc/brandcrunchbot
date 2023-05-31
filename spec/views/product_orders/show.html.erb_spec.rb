require 'rails_helper'

RSpec.describe "product_orders/show", type: :view do
  before(:each) do
    @product_order = assign(:product_order, ProductOrder.create!(
      order: nil,
      product: nil,
      finish_details: nil,
      total_price: "9.99",
      finish_price_total: "9.99"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
  end
end
