require 'rails_helper'

RSpec.describe GodaddyApi do
  before(:all) do
    @service = described_class.new
  end

  describe 'Domain Info' do
    it 'retrieves domain info', focus: true do
      domain_name = 'maby.com'
      res = @service.get_auction_details(domain_name:)
      require 'pry'; binding.pry
    end
  end
end
