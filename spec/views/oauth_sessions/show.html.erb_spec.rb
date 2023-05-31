require 'rails_helper'

RSpec.describe "oauth_sessions/show", type: :view do
  before(:each) do
    @oauth_session = assign(:oauth_session, OauthSession.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end
