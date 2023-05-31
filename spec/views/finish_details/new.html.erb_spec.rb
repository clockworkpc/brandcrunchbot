require 'rails_helper'

RSpec.describe "finish_details/new", type: :view do
  before(:each) do
    assign(:finish_detail, FinishDetail.new(
      finish_type: "MyString",
      finish_color: "MyString",
      finish_sheen: "MyString"
    ))
  end

  it "renders new finish_detail form" do
    render

    assert_select "form[action=?][method=?]", finish_details_path, "post" do

      assert_select "input[name=?]", "finish_detail[finish_type]"

      assert_select "input[name=?]", "finish_detail[finish_color]"

      assert_select "input[name=?]", "finish_detail[finish_sheen]"
    end
  end
end
