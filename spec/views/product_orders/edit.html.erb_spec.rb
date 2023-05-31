require 'rails_helper'

RSpec.describe 'product_orders/edit', type: :view do
  before do
    @product_order = assign(:product_order, ProductOrder.create!(
                                              order: nil,
                                              product: nil,
                                              finish_details: nil,
                                              total_price: '9.99',
                                              finish_price_total: '9.99'
                                            ))
  end

  it 'renders the edit product_order form' do
    render

    assert_select 'form[action=?][method=?]', product_order_path(@product_order), 'post' do
      assert_select 'input[name=?]', 'product_order[order_id]'

      assert_select 'input[name=?]', 'product_order[product_id]'

      assert_select 'input[name=?]', 'product_order[finish_detail_id]'

      assert_select 'input[name=?]', 'product_order[total_price]'

      assert_select 'input[name=?]', 'product_order[finish_price_total]'
    end
  end
end
