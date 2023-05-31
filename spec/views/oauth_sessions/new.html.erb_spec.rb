require 'rails_helper'

RSpec.describe "oauth_sessions/new", type: :view do
  before(:each) do
    assign(:oauth_session, OauthSession.new())
  end

  it "renders new oauth_session form" do
    render

    assert_select "form[action=?][method=?]", oauth_sessions_path, "post" do
    end
  end
end
