class WahaWebhooksController < ApplicationController
  # WAHA will POST JSON without CSRF token
  protect_from_forgery with: :null_session

  # POST /waha/webhooks
  def receive
    # WAHA sends { event: "...", payload: { ... } }  (modern) or
    # { event: "...", data: { ... } } (older/engine.event)
    event = params[:event]
    data  = params[:data] || params[:payload] || {}

    # Persist a lightweight event record for ops dashboard
    WahaEvent.create!(session_name: params[:session] || nil, event_name: event, payload: data)

    case event
    when "messages.upsert"
      handle_messages_upsert(data)
      head :ok
    when "message"
      handle_single_message(data)
      head :ok
    else
      Rails.logger.info "Unhandled WAHA event: #{event}"
      head :accepted
    end
  rescue StandardError => e
    Rails.logger.error "Webhook processing failed: #{e.message}\n#{e.backtrace.take(5).join("\n")}"
    head :internal_server_error
  end

  private

  def handle_single_message(msg)
    chat_id = msg["chatId"] || msg["chat_id"] || (msg["fromMe"] ? msg["to"] : msg["from"])
    return if chat_id.blank?

    chat = Chat.find_or_create_by!(wa_id: chat_id)

    body_text = if msg["body"].present?
                  msg["body"]
                elsif msg.dig("text", "body").present?
                  msg.dig("text", "body")
                end

    chat.messages.create!(
      wa_message_id: msg["id"],
      direction: msg["fromMe"] ? :outgoing : :incoming,
      message_type: msg["type"] || "text",
      body: body_text,
      payload: msg,
      sent_at: (Time.at(msg["timestamp"]).in_time_zone rescue nil)
    )
  end

  def handle_messages_upsert(data)
    Array(data["messages"]).each do |msg_payload|
      chat_id = msg_payload["chatId"] || msg_payload["chat_id"]
      next unless chat_id.present?

      chat = Chat.find_or_create_by!(wa_id: chat_id)

      # Determine direction based on `fromMe` flag
      direction = msg_payload["fromMe"] ? :outgoing : :incoming

      Message.create!(
        chat: chat,
        wa_message_id: msg_payload["id"],
        direction: direction,
        message_type: msg_payload["type"] || "text",
        body: msg_payload.dig("text", "body") || msg_payload["body"],
        payload: msg_payload,
        sent_at: (Time.at(msg_payload["timestamp"]).utc rescue nil)
      )
    end
  end
end