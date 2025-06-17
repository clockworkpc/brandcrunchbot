class OauthSessionsController < ApplicationController
  before_action :authenticate_user!, except: %i[create show]
  before_action :set_oauth_session, only: %i[show edit update destroy]

  # GET /oauth_sessions or /oauth_sessions.json
  def index
    @oauth_sessions = OauthSession.all
  end

  # GET /oauth_sessions/1 or /oauth_sessions/1.json
  def show; end

  # GET /oauth_sessions/new
  def new
    @oauth_session = OauthSession.new
  end

  # GET /oauth_sessions/1/edit
  def edit; end

  # POST /oauth_sessions or /oauth_sessions.json
  def create
    @oauth_session = OauthSession.new(oauth_session_params)

    respond_to do |format|
      if @oauth_session.save
        format.html { redirect_to oauth_session_url(@oauth_session), notice: 'Oauth session was successfully created.' }
        format.json { render :show, status: :created, location: @oauth_session }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @oauth_session.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /oauth_sessions/1 or /oauth_sessions/1.json
  def update
    respond_to do |format|
      if @oauth_session.update(oauth_session_params)
        format.html { redirect_to oauth_session_url(@oauth_session), notice: 'Oauth session was successfully updated.' }
        format.json { render :show, status: :ok, location: @oauth_session }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @oauth_session.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /oauth_sessions/1 or /oauth_sessions/1.json
  def destroy
    @oauth_session.destroy

    respond_to do |format|
      format.html { redirect_to oauth_sessions_url, notice: 'Oauth session was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_oauth_session
    @oauth_session = OauthSession.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def oauth_session_params
    params.permit(:code, :scope)
  end
end
