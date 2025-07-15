require "base64"

class WahaSessionsController < ApplicationController
  protect_from_forgery with: :null_session

  # GET /waha/sessions
  def index
    @sessions = WahaSession.order(:name)
    # Refresh profile pictures for all sessions
    @sessions.each(&:refresh_profile_picture!)
  end

  # POST /waha/sessions
  # { "name": "default" }
  def create
    name = params[:name] || "default"

    # Persist or find session locally first
    waha_session = WahaSession.find_or_initialize_by(name: name)
    waha_session.status = :pending_qr
    waha_session.save!

    # Start session on WAHA (creates if missing)
    result = WAHA.start_session(name: name)

    # Refresh profile picture after session is started
    waha_session.refresh_profile_picture!

    respond_to do |format|
      format.json { render json: result }
      format.html { redirect_to waha_sessions_path, notice: "Session '#{name}' started. Scan the QR code to connect." }
    end
  rescue WahaClient::Error => e
    waha_session.update(status: :error) if waha_session&.persisted?
    respond_to do |format|
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
      format.html { redirect_to waha_sessions_path, alert: e.message }
    end
  end

  # GET /waha/qr?session=default
  def qr
    session_name = params[:session] || "default"
    # Get raw QR code value (string) – this endpoint does not touch the
    # browser context in WAHA, preventing the TargetCloseError crash.
    raw_response = WAHA.qr(session: session_name, format: "raw")
    qr_value = raw_response.is_a?(Hash) ? raw_response[:value] || raw_response["value"] : raw_response

    require "rqrcode"
    qrcode = RQRCode::QRCode.new(qr_value)
    png = qrcode.as_png(size: 300)
    png_data = png.to_s

    WahaSession.where(name: session_name).update_all(last_qr_generated_at: Time.current)

    if request.format.png?
      send_data png_data, type: "image/png", disposition: "inline"
      return
    end

    data_uri = Base64.strict_encode64(png_data)
    @qr_src = "data:image/png;base64,#{data_uri}"
    @session_name = session_name
  rescue WahaClient::Error => e
    render plain: e.message, status: :bad_gateway
  end

  # DELETE /waha/sessions/:id
  def destroy
    waha_session = WahaSession.find(params[:id])

    begin
      WAHA.delete_session(name: waha_session.name)
    rescue WahaClient::Error => e
      # Log but continue deleting locally so UI stays clean
      Rails.logger.warn("WAHA delete failed for session #{waha_session.name}: #{e.message}")
    end

    waha_session.destroy

    respond_to do |format|
      format.html { redirect_to waha_sessions_path, notice: "Session '#{waha_session.name}' deleted." }
      format.json { head :no_content }
    end
  end

  private

  def waha_session_params
    params.require(:waha_session).permit(:name)
  end
end