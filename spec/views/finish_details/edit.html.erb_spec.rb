require 'rails_helper'

RSpec.describe "finish_details/edit", type: :view do
  before(:each) do
    @finish_detail = assign(:finish_detail, FinishDetail.create!(
      finish_type: "MyString",
      finish_color: "MyString",
      finish_sheen: "MyString"
    ))
  end

  it "renders the edit finish_detail form" do
    render

    assert_select "form[action=?][method=?]", finish_detail_path(@finish_detail), "post" do

      assert_select "input[name=?]", "finish_detail[finish_type]"

      assert_select "input[name=?]", "finish_detail[finish_color]"

      assert_select "input[name=?]", "finish_detail[finish_sheen]"
    end
  end
end
