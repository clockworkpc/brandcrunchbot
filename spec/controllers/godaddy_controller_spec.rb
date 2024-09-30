require 'rails_helper'

RSpec.describe GodaddyController, type: :controller do
  render_views

  let(:webhook_params) do
    { 'sheetName' => 'domains',
      'changes' => { 'R103C1' => 'goodgood.com', 'R103C2' => '', 'R103C3' => 5, 'R104C1' => 'feelsgood.com.au',
                     'R104C2' => '', 'R104C3' => 5 },
      'godaddy' => { 'sheetName' => 'domains',
                     'changes' => { 'R103C1' => 'goodgood.com', 'R103C2' => '', 'R103C3' => 5, 'R104C1' => 'feelsgood.com.au',
                                    'R104C2' => '', 'R104C3' => 5 } } }
  end

  let(:response_json) do
    { 'sheetName' => 'domains',
      'changes' => { 'R103C1' => 'goodgood.com',
                     'R103C2' => '',
                     'R103C3' => '5',
                     'R104C1' => 'feelsgood.com.au',
                     'R104C2' => '',
                     'R104C3' => '5' } }.to_json
  end

  describe 'POST #google_sheet' do
    it 'returns 200 with params in JSON', :focus do
      post :google_sheet, params: webhook_params
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(response_json)
    end
  end
end
