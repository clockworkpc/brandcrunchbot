require 'rails_helper'

RSpec.describe FinishDetailsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/finish_details').to route_to('finish_details#index')
    end

    it 'routes to #new' do
      expect(get: '/finish_details/new').to route_to('finish_details#new')
    end

    it 'routes to #show' do
      expect(get: '/finish_details/1').to route_to('finish_details#show', id: '1')
    end

    it 'routes to #edit' do
      expect(get: '/finish_details/1/edit').to route_to('finish_details#edit', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/finish_details').to route_to('finish_details#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/finish_details/1').to route_to('finish_details#update', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/finish_details/1').to route_to('finish_details#update', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/finish_details/1').to route_to('finish_details#destroy', id: '1')
    end
  end
end
