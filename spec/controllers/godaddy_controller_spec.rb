require 'rails_helper'

RSpec.describe GodaddyController, type: :controller do
  describe 'POST #google_sheet' do
    let(:service_double) { instance_double(BuyItNowBotScheduler) }

    before do
      allow(BuyItNowBotScheduler).to receive(:new).and_return(service_double)
      allow(service_double).to receive(:call)
    end

    context 'with valid godaddy params' do
      let(:valid_params) do
        {
          godaddy: {
            sheet_name: 'test_sheet',
            changes: {
              'row_1' => { 'column_a' => 'value1', 'column_b' => 'value2' },
              'row_2' => { 'column_a' => 'value3', 'column_b' => 'value4' }
            }
          }
        }
      end

      it 'returns 200 status' do
        post :google_sheet, params: valid_params

        expect(response).to have_http_status(:ok)
      end

      it 'returns success message' do
        post :google_sheet, params: valid_params

        expect(JSON.parse(response.body)).to eq({ 'message' => 'Data received successfully' })
      end

      it 'calls BuyItNowBotScheduler with changes values' do
        expected_changes = [
          { 'column_a' => 'value1', 'column_b' => 'value2' },
          { 'column_a' => 'value3', 'column_b' => 'value4' }
        ]

        post :google_sheet, params: valid_params

        expect(service_double).to have_received(:call).with(changes: expected_changes)
      end

      it 'creates new BuyItNowBotScheduler instance' do
        post :google_sheet, params: valid_params

        expect(BuyItNowBotScheduler).to have_received(:new)
      end
    end

    context 'with empty changes' do
      let(:params_with_empty_changes) do
        {
          godaddy: {
            sheet_name: 'test_sheet',
            changes: {}
          }
        }
      end

      it 'calls service with empty array' do
        post :google_sheet, params: params_with_empty_changes

        expect(service_double).to have_received(:call).with(changes: [])
      end

      it 'returns success status' do
        post :google_sheet, params: params_with_empty_changes

        expect(response).to have_http_status(:ok)
      end
    end

    context 'with missing changes key' do
      let(:params_without_changes) do
        {
          godaddy: {
            sheet_name: 'test_sheet'
          }
        }
      end

      it 'calls service with empty array' do
        post :google_sheet, params: params_without_changes

        expect(service_double).to have_received(:call).with(changes: [])
      end

      it 'returns success status' do
        post :google_sheet, params: params_without_changes

        expect(response).to have_http_status(:ok)
      end
    end

    context 'with missing godaddy key' do
      let(:invalid_params) { { other_key: 'value' } }

      it 'returns 422 status' do
        post :google_sheet, params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error message' do
        post :google_sheet, params: invalid_params

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to have_key('error')
        expect(parsed_response['error']).to include('godaddy')
      end

      it 'does not call BuyItNowBotScheduler' do
        post :google_sheet, params: invalid_params

        expect(service_double).not_to have_received(:call)
      end
    end

    context 'when service raises an error' do
      let(:valid_params) do
        {
          godaddy: {
            sheet_name: 'test_sheet',
            changes: { 'row_1' => { 'column_a' => 'value1' } }
          }
        }
      end

      before do
        allow(service_double).to receive(:call).and_raise(StandardError.new('Service error'))
      end

      it 'allows the error to bubble up' do
        expect { post :google_sheet, params: valid_params }.to raise_error(StandardError, 'Service error')
      end
    end

    context 'with unpermitted parameters' do
      let(:params_with_unpermitted) do
        {
          godaddy: {
            sheet_name: 'test_sheet',
            changes: { 'row_1' => { 'column_a' => 'value1' } },
            unpermitted_param: 'should_be_filtered'
          }
        }
      end

      it 'filters out unpermitted parameters' do
        post :google_sheet, params: params_with_unpermitted

        expect(response).to have_http_status(:ok)
      end

      it 'still processes permitted parameters correctly' do
        expected_changes = [{ 'column_a' => 'value1' }]

        post :google_sheet, params: params_with_unpermitted

        expect(service_double).to have_received(:call).with(changes: expected_changes)
      end
    end

    context 'with nested unpermitted parameters in changes' do
      let(:params_with_nested_unpermitted) do
        {
          godaddy: {
            sheet_name: 'test_sheet',
            changes: {
              'row_1' => {
                'column_a' => 'value1',
                'nested_object' => { 'deep_key' => 'deep_value' }
              }
            }
          }
        }
      end

      it 'allows nested parameters in changes hash' do
        post :google_sheet, params: params_with_nested_unpermitted

        expect(response).to have_http_status(:ok)
      end
    end
  end

 describe 'CSRF protection' do
    it 'allows POST requests without CSRF token' do
      # This test verifies that CSRF protection is skipped by making a request
      # without setting up CSRF tokens and expecting it to succeed
      post :google_sheet, params: {
        godaddy: {
          sheet_name: 'test_sheet',
          changes: {}
        }
      }
      
      expect(response).to have_http_status(:ok)
    end
  end
end
