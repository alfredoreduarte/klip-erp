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
    when "presence.update"
      handle_presence_update(data)
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

    # Associate chat with session
    session_name = params[:session].presence
    waha_session = session_name.present? ? WahaSession.find_or_create_by!(name: session_name) : nil

    chat = Chat.find_or_create_by!(wa_id: chat_id)
    if waha_session && chat.waha_session_id.nil?
      chat.update(waha_session: waha_session)
    end
    # Always attempt to fetch latest profile picture
    chat.refresh_profile!(session_name)

    # Update name from message data if available and not already set
    if msg["pushName"].present?
      chat.update_name_from_message!(msg["pushName"])
    end

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

      # Find or create session if provided
      session_name = params[:session].presence
      waha_session = session_name.present? ? WahaSession.find_or_create_by!(name: session_name) : nil

      chat = Chat.find_or_create_by!(wa_id: chat_id)
      if waha_session && chat.waha_session_id.nil?
        chat.update(waha_session: waha_session)
      end
      # Always attempt to fetch latest profile picture
      chat.refresh_profile!(session_name)

      # Update name from message data if available and not already set
      if msg_payload["pushName"].present?
        chat.update_name_from_message!(msg_payload["pushName"])
      end

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

  def handle_presence_update(payload)
    chat_wa_id = payload["id"] || payload["chatId"]
    return if chat_wa_id.blank?

    chat = Chat.find_by(wa_id: chat_wa_id)
    return unless chat

    # Determine if any participant (other than us) is typing/composing.
    typing = Array(payload["presences"]).any? do |p|
      status = p["lastKnownPresence"]

      # Skip entries that refer to our own account. WAHA marks these with
      # `isSelf` (boolean). Fallback to checking `participant` when present
      # but equal to the session wid (if available) or not equal to the chat id
      next false if p["isSelf"]

      participant = p["participant"]
      # In 1-to-1 chats `participant` may be nil. When present, ignore if it
      # matches our chat wa_id (the remote contact) OR looks like our own wa_id.
      # For our purpose we only care about other participant(s), so require a
      # presence entry that is NOT self and not the chat itself (group case).

      %w[typing composing recording-audio].include?(status)
    end

    Turbo::StreamsChannel.broadcast_update_to(
      "chat_presence_#{chat.id}",
      target: "typing-indicator",
      partial: "chats/typing_indicator",
      locals: { chat: chat, show: typing }
    )
  end
end