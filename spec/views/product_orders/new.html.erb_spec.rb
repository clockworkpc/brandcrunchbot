require 'rails_helper'

RSpec.describe 'product_orders/new', type: :view do
  before do
    assign(:product_order, ProductOrder.new(
                             order: nil,
                             product: nil,
                             finish_details: nil,
                             total_price: '9.99',
                             finish_price_total: '9.99'
                           ))
  end

  it 'renders new product_order form' do
    render

    assert_select 'form[action=?][method=?]', product_orders_path, 'post' do
      assert_select 'input[name=?]', 'product_order[order_id]'

      assert_select 'input[name=?]', 'product_order[product_id]'

      assert_select 'input[name=?]', 'product_order[finish_details_id]'

      assert_select 'input[name=?]', 'product_order[total_price]'

      assert_select 'input[name=?]', 'product_order[finish_price_total]'
    end
  end
end
