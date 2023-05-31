require 'rails_helper'

RSpec.describe "orders/new", type: :view do
  before(:each) do
    assign(:order, Order.new(
      customer: nil,
      order_number: 1
    ))
  end

  it "renders new order form" do
    render

    assert_select "form[action=?][method=?]", orders_path, "post" do

      assert_select "input[name=?]", "order[customer_id]"

      assert_select "input[name=?]", "order[order_number]"
    end
  end
end
