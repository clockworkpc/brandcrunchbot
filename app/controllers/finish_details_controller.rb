class FinishDetailsController < ApplicationController
  before_action :set_finish_detail, only: %i[ show edit update destroy ]

  # GET /finish_details or /finish_details.json
  def index
    @finish_details = FinishDetail.all
  end

  # GET /finish_details/1 or /finish_details/1.json
  def show
  end

  # GET /finish_details/new
  def new
    @finish_detail = FinishDetail.new
  end

  # GET /finish_details/1/edit
  def edit
  end

  # POST /finish_details or /finish_details.json
  def create
    @finish_detail = FinishDetail.new(finish_detail_params)

    respond_to do |format|
      if @finish_detail.save
        format.html { redirect_to finish_detail_url(@finish_detail), notice: "Finish detail was successfully created." }
        format.json { render :show, status: :created, location: @finish_detail }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @finish_detail.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /finish_details/1 or /finish_details/1.json
  def update
    respond_to do |format|
      if @finish_detail.update(finish_detail_params)
        format.html { redirect_to finish_detail_url(@finish_detail), notice: "Finish detail was successfully updated." }
        format.json { render :show, status: :ok, location: @finish_detail }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @finish_detail.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /finish_details/1 or /finish_details/1.json
  def destroy
    @finish_detail.destroy

    respond_to do |format|
      format.html { redirect_to finish_details_url, notice: "Finish detail was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_finish_detail
      @finish_detail = FinishDetail.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def finish_detail_params
      params.require(:finish_detail).permit(:finish_type, :finish_color, :finish_sheen)
    end
end
