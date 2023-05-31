require 'rails_helper'

RSpec.describe "finish_details/index", type: :view do
  before(:each) do
    assign(:finish_details, [
      FinishDetail.create!(
        finish_type: "Finish Type",
        finish_color: "Finish Color",
        finish_sheen: "Finish Sheen"
      ),
      FinishDetail.create!(
        finish_type: "Finish Type",
        finish_color: "Finish Color",
        finish_sheen: "Finish Sheen"
      )
    ])
  end

  it "renders a list of finish_details" do
    render
    assert_select "tr>td", text: "Finish Type".to_s, count: 2
    assert_select "tr>td", text: "Finish Color".to_s, count: 2
    assert_select "tr>td", text: "Finish Sheen".to_s, count: 2
  end
end
