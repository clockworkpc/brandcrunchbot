require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to test the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator. If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails. There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.

RSpec.describe "/oauth_sessions", type: :request do
  
  # This should return the minimal set of attributes required to create a valid
  # OauthSession. As you add validations to OauthSession, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    skip("Add a hash of attributes valid for your model")
  }

  let(:invalid_attributes) {
    skip("Add a hash of attributes invalid for your model")
  }

  describe "GET /index" do
    it "renders a successful response" do
      OauthSession.create! valid_attributes
      get oauth_sessions_url
      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      oauth_session = OauthSession.create! valid_attributes
      get oauth_session_url(oauth_session)
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    it "renders a successful response" do
      get new_oauth_session_url
      expect(response).to be_successful
    end
  end

  describe "GET /edit" do
    it "renders a successful response" do
      oauth_session = OauthSession.create! valid_attributes
      get edit_oauth_session_url(oauth_session)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new OauthSession" do
        expect {
          post oauth_sessions_url, params: { oauth_session: valid_attributes }
        }.to change(OauthSession, :count).by(1)
      end

      it "redirects to the created oauth_session" do
        post oauth_sessions_url, params: { oauth_session: valid_attributes }
        expect(response).to redirect_to(oauth_session_url(OauthSession.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a new OauthSession" do
        expect {
          post oauth_sessions_url, params: { oauth_session: invalid_attributes }
        }.to change(OauthSession, :count).by(0)
      end

      it "renders a successful response (i.e. to display the 'new' template)" do
        post oauth_sessions_url, params: { oauth_session: invalid_attributes }
        expect(response).to be_successful
      end
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:new_attributes) {
        skip("Add a hash of attributes valid for your model")
      }

      it "updates the requested oauth_session" do
        oauth_session = OauthSession.create! valid_attributes
        patch oauth_session_url(oauth_session), params: { oauth_session: new_attributes }
        oauth_session.reload
        skip("Add assertions for updated state")
      end

      it "redirects to the oauth_session" do
        oauth_session = OauthSession.create! valid_attributes
        patch oauth_session_url(oauth_session), params: { oauth_session: new_attributes }
        oauth_session.reload
        expect(response).to redirect_to(oauth_session_url(oauth_session))
      end
    end

    context "with invalid parameters" do
      it "renders a successful response (i.e. to display the 'edit' template)" do
        oauth_session = OauthSession.create! valid_attributes
        patch oauth_session_url(oauth_session), params: { oauth_session: invalid_attributes }
        expect(response).to be_successful
      end
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested oauth_session" do
      oauth_session = OauthSession.create! valid_attributes
      expect {
        delete oauth_session_url(oauth_session)
      }.to change(OauthSession, :count).by(-1)
    end

    it "redirects to the oauth_sessions list" do
      oauth_session = OauthSession.create! valid_attributes
      delete oauth_session_url(oauth_session)
      expect(response).to redirect_to(oauth_sessions_url)
    end
  end
end