require 'rails_helper'

RSpec.describe 'product_orders/index', type: :view do
  before do
    assign(:product_orders, [
             ProductOrder.create!(
               order: nil,
               product: nil,
               finish_details: nil,
               total_price: '9.99',
               finish_price_total: '9.99'
             ),
             ProductOrder.create!(
               order: nil,
               product: nil,
               finish_details: nil,
               total_price: '9.99',
               finish_price_total: '9.99'
             )
           ])
  end

  it 'renders a list of product_orders' do
    render
    assert_select 'tr>td', text: nil.to_s, count: 2
    assert_select 'tr>td', text: nil.to_s, count: 2
    assert_select 'tr>td', text: nil.to_s, count: 2
    assert_select 'tr>td', text: 2.to_s, count: 2
    assert_select 'tr>td', text: '9.99'.to_s, count: 2
    assert_select 'tr>td', text: '9.99'.to_s, count: 2
  end
end
