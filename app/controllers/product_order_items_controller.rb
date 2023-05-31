class ProductOrderItemsController < ApplicationController
  before_action :set_product_order_item, only: %i[ show edit update destroy ]

  # GET /product_order_items or /product_order_items.json
  def index
    @product_order_items = ProductOrderItem.all
  end

  # GET /product_order_items/1 or /product_order_items/1.json
  def show
  end

  # GET /product_order_items/new
  def new
    @product_order_item = ProductOrderItem.new
  end

  # GET /product_order_items/1/edit
  def edit
  end

  # POST /product_order_items or /product_order_items.json
  def create
    @product_order_item = ProductOrderItem.new(product_order_item_params)

    respond_to do |format|
      if @product_order_item.save
        format.html { redirect_to product_order_item_url(@product_order_item), notice: "Product order item was successfully created." }
        format.json { render :show, status: :created, location: @product_order_item }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @product_order_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /product_order_items/1 or /product_order_items/1.json
  def update
    respond_to do |format|
      if @product_order_item.update(product_order_item_params)
        format.html { redirect_to product_order_item_url(@product_order_item), notice: "Product order item was successfully updated." }
        format.json { render :show, status: :ok, location: @product_order_item }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @product_order_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /product_order_items/1 or /product_order_items/1.json
  def destroy
    @product_order_item.destroy

    respond_to do |format|
      format.html { redirect_to product_order_items_url, notice: "Product order item was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product_order_item
      @product_order_item = ProductOrderItem.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def product_order_item_params
      params.require(:product_order_item).permit(:product_order_id, :line_number, :unit_price, :finish_price, :quantity, :specialty_price, :line_total)
    end
end
