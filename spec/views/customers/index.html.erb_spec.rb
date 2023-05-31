require 'rails_helper'

RSpec.describe "customers/index", type: :view do
  before(:each) do
    assign(:customers, [
      Customer.create!(
        customer_id: 2,
        customer_name: "Customer Name"
      ),
      Customer.create!(
        customer_id: 2,
        customer_name: "Customer Name"
      )
    ])
  end

  it "renders a list of customers" do
    render
    assert_select "tr>td", text: 2.to_s, count: 2
    assert_select "tr>td", text: "Customer Name".to_s, count: 2
  end
end
