require 'rails_helper'

RSpec.describe DomainChecker do
  before do
    @service = described_class.new
  end

  describe 'Unavailable Domain' do
    it 'hello world' do
      expect(@service.hello_world).to eq('hello world')
    end
  end
end
