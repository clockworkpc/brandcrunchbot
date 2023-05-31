require 'rails_helper'

RSpec.describe "oauth_sessions/edit", type: :view do
  before(:each) do
    @oauth_session = assign(:oauth_session, OauthSession.create!())
  end

  it "renders the edit oauth_session form" do
    render

    assert_select "form[action=?][method=?]", oauth_session_path(@oauth_session), "post" do
    end
  end
end
