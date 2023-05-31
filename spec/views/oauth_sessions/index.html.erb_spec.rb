require 'rails_helper'

RSpec.describe "oauth_sessions/index", type: :view do
  before(:each) do
    assign(:oauth_sessions, [
      OauthSession.create!(),
      OauthSession.create!()
    ])
  end

  it "renders a list of oauth_sessions" do
    render
  end
end
