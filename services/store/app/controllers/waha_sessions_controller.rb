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
    data = WAHA.screenshot(session: params[:session] || "default")

    # If the client explicitly asks for a PNG (e.g. /waha/qr.png or
    # /waha/qr?format=png) we stream the binary directly.  Rails will route
    # "/waha/qr.png" here with `format` param set to "png", so we rely on the
    # request's format instead of a separate `qr_png` action.
    if request.format.png?
      send_data data, type: "image/png", disposition: "inline"
      return
    end

    # Otherwise render an HTML page embedding the base64-encoded screenshot so
    # that it refreshes automatically via Turbo / HTMX or a normal browser
    # refresh.
    unless data.is_a?(String)
      render plain: "Unexpected response", status: :bad_gateway and return
    end

    data_uri = Base64.strict_encode64(data)
    @qr_src = "data:image/png;base64,#{data_uri}"
  rescue WahaClient::Error => e
    render plain: e.message, status: :bad_gateway
  end
end