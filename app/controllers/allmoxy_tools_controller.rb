class AllmoxyToolsController < ApplicationController # rubocop:disable Metrics/ClassLength
  before_action :authenticate_user!
  before_action :log_current_user
  before_action :slack_current_user, only: %i[refresh_report
                                              completed_orders
                                              update_sales_customers]

  def index
    respond_to do |format|
      if current_user.authorized?
        format.html { render :index, status: :ok }
      else
        format.html { render :forbidden, status: :forbidden }
      end
    end
  end

  def refresh_report
    service = AllmoxyToolsService.new
    service.delay.refresh_report(allmoxy_report_params)
    notice = 'Scheduling inputs are being refreshed...'

    respond_to do |format|
      format.html { redirect_to allmoxy_tools_url, notice: }
    end
  end

  def completed_orders
    service = AllmoxyToolsService.new
    service.generate_product_order_records(completed_order_params)
    service.update_finish_price_tracking(completed_order_params)
    notice = 'Completed records are being retrieved...'

    respond_to do |format|
      format.html { redirect_to allmoxy_tools_url, notice: }
    end
  end

  def completed_orders_csv
    service = AllmoxyToolsService.new

    prod_path = upload_params[:uploaded_csv].path
    dev_path = "#{upload_params[:uploaded_csv].path}B"
    FileUtils.copy_entry(prod_path, dev_path)
    uploaded_csv = Rails.env.eql?('production') ? prod_path : dev_path
    service.generate_product_order_records(upload_params, uploaded_csv)
    notice = 'Updating records from CSV...'

    respond_to do |format|
      format.html { redirect_to allmoxy_tools_url, notice: }
    end
  end

  def update_sales_customers
    service = AllmoxyToolsService.new
    service.delay.update_sales_customers(allmoxy_customer_params)
    notice = 'Updating Customer Records...'

    respond_to do |format|
      format.html { redirect_to allmoxy_tools_url, notice: }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_allmoxy_tool
    @allmoxy_tool = AllmoxyTool.find(params[:id])
  end

  def allmoxy_tool_params
    params.fetch(:allmoxy_tool, {})
  end

  def allmoxy_report_params # rubocop:disable Metrics/MethodLength
    params.permit(
      :authenticity_token,
      :dev,
      :commit,
      :shipping_report,
      :orders_report_doors,
      :orders_report_boxes,
      :orders_report_finish,
      :orders_report_specialty,
      :orders_report_dev,
      :orders_report_doors_v5,
      :product_tags_report,
      :phpsessid,
      :product_attributes_backup,
      :product_order_items,
      :projection_report
    )
  end

  def order_report_params
    params.permit(
      :authenticity_token,
      :dev,
      :commit,
      :orders_report_doors_v5,
      :orders_report_boxes,
      :orders_report_finish,
      :orders_report_specialty,
      :orders_report_production_scheduling
    )
  end

  def completed_order_params
    params.permit(
      :button,
      :authenticity_token,
      :start_date,
      :end_date
    )
  end

  def upload_params
    params.permit(
      :uploaded_csv,
      :authenticity_token,
      :commit
    )
  end

  def allmoxy_customer_params
    params.permit(
      :authenticity_token,
      :commit,
      :update_sales_customers
    )
  end
end
