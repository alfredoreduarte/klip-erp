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
    png = WAHA.screenshot(session: params[:session] || "default")
    unless png.is_a?(String)
      render plain: "Unexpected response", status: :bad_gateway and return
    end
    data_uri = Base64.strict_encode64(png)
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