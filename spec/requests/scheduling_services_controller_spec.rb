require 'rails_helper'

RSpec.describe SchedulingServicesController, type: :controller do
  let(:ancillary_input_params) { { projection_report: 1, shipping_report: 1 } }
  let(:v4_input_params) { { doors_v5_inputs: 1, drawers_v5_inputs: 1, specialty_v5_inputs: 1, finish_v5_inputs: 1 } }
  let(:production_input_params) { { doors_inputs: 1, drawers_inputs: 1 } }
  let(:all_input_params) { { all_v4_inputs: 1, all_production_inputs: 1 } }

  before(:all) do
    Delayed::Worker.delay_jobs = false
  end

  before do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    @user = create(:user, email: 'alexander@panhandledoor.com')
    sign_in @user
  end

  after do
    sign_out @user
  end

  describe 'GET /index' do
    it 'has a status code of 200' do
      get :index
      expect(response).to have_http_status(:ok)
    end

    describe 'Ancillary Inputs' do
      it 'posts an empty form to ancillary_inputs' do
        post :ancillary_inputs, params: nil
        expect(response).to have_http_status(:found)
      end

      it 'posts to ancillary_inputs', focus: false do
        post :ancillary_inputs, params: ancillary_input_params
        expect(response).to have_http_status(:found)
      end

      it 'posts to ancillary_inputs, Projection Report only', focus: false do
        post :ancillary_inputs, params: { projection_report: 1 }
        expect(response).to have_http_status(:found)
      end

      it 'posts to ancillary_inputs, Number Tags only', focus: false do
        post :ancillary_inputs, params: { tags_report: 1 }
        expect(response).to have_http_status(:found)
      end
    end

    describe 'V4 Inputs' do
      it 'posts to v4_inputs for doors only', focus: false do
        post :v4_inputs, params: { doors_v5_inputs: 1 }
        expect(response).to have_http_status(:found)
      end

      it 'posts to v4_inputs for drawers only', focus: false do
        post :v4_inputs, params: { drawers_v5_inputs: 1 }
        expect(response).to have_http_status(:found)
      end

      it 'posts to v4_inputs for specialty only', focus: false do
        post :v4_inputs, params: { specialty_v5_inputs: 1 }
        expect(response).to have_http_status(:found)
      end

      it 'posts to v4_inputs for finish only', focus: false do
        post :v4_inputs, params: { finish_v5_inputs: 1 }
        expect(response).to have_http_status(:found)
      end

      it 'posts to all v4_inputs', focus: false do
        post :v4_inputs, params: v4_input_params
        expect(response).to have_http_status(:found)
      end
    end

    describe 'Production Inputs' do
      it 'posts to production_inputs for doors only', focus: false do
        post :production_inputs, params: { doors_inputs: 1 }
        expect(response).to have_http_status(:found)
      end

      # it 'posts to production_inputs for drawers only', focus: true do
      #   post :production_inputs, params: { drawers_inputs: 1 }
      #   expect(response).to have_http_status(:found)
      # end

      it 'posts to production_inputs', focus: false do
        post :production_inputs, params: production_input_params
        expect(response).to have_http_status(:found)
      end
    end

    it 'posts to all_inputs' do
      post :all_inputs, params: all_input_params
      expect(response).to have_http_status(:found)
    end
  end
end
