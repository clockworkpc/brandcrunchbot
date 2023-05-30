require 'rails_helper'

RSpec.describe BuyItNowBot do
  it 'attempts to purchase a given domain', focus: true do
    domain_name = 'esgapi.com'
    # domain_name = 'cannaphresh.com'
    target_price = 40
    service = described_class.new
    res = service.call(domain_name:, target_price:)
  end
end
