require 'rails_helper'

RSpec.describe "customers/show", type: :view do
  before(:each) do
    @customer = assign(:customer, Customer.create!(
      customer_id: 2,
      customer_name: "Customer Name"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/2/)
    expect(rendered).to match(/Customer Name/)
  end
end
