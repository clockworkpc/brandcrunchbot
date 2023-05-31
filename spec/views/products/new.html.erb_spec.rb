require 'rails_helper'

RSpec.describe "products/new", type: :view do
  before(:each) do
    assign(:product, Product.new(
      product_id: 1,
      product_name: "MyString"
    ))
  end

  it "renders new product form" do
    render

    assert_select "form[action=?][method=?]", products_path, "post" do

      assert_select "input[name=?]", "product[product_id]"

      assert_select "input[name=?]", "product[product_name]"
    end
  end
end
