require 'rails_helper'

RSpec.describe "customers/edit", type: :view do
  before(:each) do
    @customer = assign(:customer, Customer.create!(
      customer_id: 1,
      customer_name: "MyString"
    ))
  end

  it "renders the edit customer form" do
    render

    assert_select "form[action=?][method=?]", customer_path(@customer), "post" do

      assert_select "input[name=?]", "customer[customer_id]"

      assert_select "input[name=?]", "customer[customer_name]"
    end
  end
end
