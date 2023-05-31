require 'csv'

class ProductOrdersController < ApplicationController
  before_action :set_product_order, only: %i[show edit update destroy]

  # GET /product_orders or /product_orders.json
  def index
    @product_orders = ProductOrder.all
  end

  # GET /product_orders/1 or /product_orders/1.json
  def show
  end

  # GET /product_orders/new
  def new
    @product_order = ProductOrder.new
  end

  # GET /product_orders/1/edit
  def edit
  end

  # POST /product_orders or /product_orders.json
  def create
    @product_order = ProductOrder.new(product_order_params)

    respond_to do |format|
      if @product_order.save
        format.html { redirect_to product_order_url(@product_order), notice: 'Product order was successfully created.' }
        format.json { render :show, status: :created, location: @product_order }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @product_order.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /product_orders/1 or /product_orders/1.json
  def update
    respond_to do |format|
      if @product_order.update(product_order_params)
        format.html { redirect_to product_order_url(@product_order), notice: 'Product order was successfully updated.' }
        format.json { render :show, status: :ok, location: @product_order }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @product_order.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /product_orders/1 or /product_orders/1.json
  def destroy
    @product_order.destroy

    respond_to do |format|
      format.html { redirect_to product_orders_url, notice: 'Product order was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def finish_pricing
    @finish_product_orders = finish_product_orders_qr

    respond_to do |format|
      format.html { render :finish_pricing }
    end
  end

  def finish_pricing_csv
    query_response = finish_product_orders_qr
    my_csv = finish_product_orders_csv(query_response:)

    respond_to do |format|
      filename = "finish_records_#{DateTime.now.iso8601}.csv"
      format.html { send_data my_csv, filename: }
    end
  end

  private

  def finish_pricing_attributes
    %w[
      order_number
      customer_name
      ship_date
      completed_at
      product_name
      line_subtotal
      finish_price
      qty
    ]
  end

  def finish_product_orders_sql
    [
      'product_orders.*',
      'customers.customer_name AS customer_name',
      'orders.order_number AS order_number',
      'orders.ship_date AS ship_date',
      'orders.completed_at AS completed_at',
      'products.product_name AS product_name'
    ].join(', ')
  end

  def finish_product_orders_qr
    ProductOrder
      .select(finish_product_orders_sql)
      .joins(order: :customer)
      .joins(:product)
      .joins(:finish_detail)
      .order(:order_number)
  end

  def finish_product_orders_csv(query_response:)
    attributes = finish_pricing_attributes
    CSV.generate(headers: true) do |csv|
      csv << attributes
      query_response.each do |response_objekt|
        csv << attributes.map { |attr| response_objekt.send(attr) }
      end
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_product_order
    @product_order = ProductOrder.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def product_order_params
    params.require(:product_order).permit(:order_id, :product_id, :finish_detail_id, :total_price,
                                          :finish_price_total)
  end
end
