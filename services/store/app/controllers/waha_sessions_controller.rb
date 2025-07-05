require "base64"

class WahaSessionsController < ApplicationController
  protect_from_forgery with: :null_session

  # POST /waha/sessions
  # { "name": "default" }
  def create
    name = params[:name] || "default"
    result = WAHA.start_session(name: name)
    render json: result
  rescue WahaClient::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # GET /waha/qr?session=default
  def qr
    data_uri = Base64.strict_encode64(WAHA.screenshot(session: params[:session] || "default"))
    @qr_src = "data:image/png;base64,#{data_uri}"
  rescue WahaClient::Error => e
    render plain: e.message, status: :bad_gateway
  end

  # GET /waha/qr.png?session=default
  def qr_png
    data = WAHA.screenshot(session: params[:session] || "default")
    send_data data, type: "image/png", disposition: "inline"
  rescue WahaClient::Error => e
    render plain: e.message, status: :bad_gateway
  end
end