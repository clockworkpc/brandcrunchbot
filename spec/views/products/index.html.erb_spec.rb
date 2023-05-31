require 'rails_helper'

RSpec.describe "products/index", type: :view do
  before(:each) do
    assign(:products, [
      Product.create!(
        product_id: 2,
        product_name: "Product Name"
      ),
      Product.create!(
        product_id: 2,
        product_name: "Product Name"
      )
    ])
  end

  it "renders a list of products" do
    render
    assert_select "tr>td", text: 2.to_s, count: 2
    assert_select "tr>td", text: "Product Name".to_s, count: 2
  end
end
