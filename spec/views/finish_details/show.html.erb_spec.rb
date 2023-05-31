require 'rails_helper'

RSpec.describe "finish_details/show", type: :view do
  before(:each) do
    @finish_detail = assign(:finish_detail, FinishDetail.create!(
      finish_type: "Finish Type",
      finish_color: "Finish Color",
      finish_sheen: "Finish Sheen"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Finish Type/)
    expect(rendered).to match(/Finish Color/)
    expect(rendered).to match(/Finish Sheen/)
  end
end
