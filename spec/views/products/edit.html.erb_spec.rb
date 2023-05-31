require 'rails_helper'

RSpec.describe "products/edit", type: :view do
  before(:each) do
    @product = assign(:product, Product.create!(
      product_id: 1,
      product_name: "MyString"
    ))
  end

  it "renders the edit product form" do
    render

    assert_select "form[action=?][method=?]", product_path(@product), "post" do

      assert_select "input[name=?]", "product[product_id]"

      assert_select "input[name=?]", "product[product_name]"
    end
  end
end
