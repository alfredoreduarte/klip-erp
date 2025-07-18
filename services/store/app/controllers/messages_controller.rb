class MessagesController < ApplicationController
  def create
    @chat = Chat.find(params[:chat_id])
    text = params.require(:message)[:body]

    # Send via WAHA
    phone_number = @chat.wa_id.split("@").first
    session_name = @chat.waha_session&.name || "default"
    begin
      WAHA.send_text(phone_number: phone_number, text: text, session: session_name)
    rescue WahaClient::Error => e
      if e.message.include?("We didn't find a session")
        # Auto-heal: (re)start session and retry once
        WAHA.start_session(name: session_name)
        WAHA.send_text(phone_number: phone_number, text: text, session: session_name)
      else
        raise
      end
    end

    # Persist outgoing message
    message = @chat.messages.create!(
      direction: :outgoing,
      message_type: "text",
      body: text,
      wa_message_id: SecureRandom.uuid,
      payload: {},
      sent_at: Time.current
    )

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.append("chat_#{@chat.id}_messages", partial: "messages/message", locals: { message: message }) }
      format.html { redirect_to chat_path(@chat) }
    end
  rescue WahaClient::Error => e
    redirect_to chat_path(@chat), alert: e.message
  end

  def pin
    @message = Message.find(params[:id])
    duration = params[:duration]&.to_i || 86400 # Default to 24 hours

    @message.pin!(duration: duration)

    # Sync state after pinning to ensure UI reflects actual state
    @message.sync_pin_state!

    respond_to do |format|
      format.turbo_stream { head :ok }
      format.html { redirect_back(fallback_location: chat_path(@message.chat)) }
    end
  rescue WahaClient::Error => e
    redirect_back(fallback_location: chat_path(@message.chat), alert: "Failed to pin message: #{e.message}")
  end

  def unpin
    @message = Message.find(params[:id])
    @message.unpin!

    # Sync state after unpinning to ensure UI reflects actual state
    @message.sync_pin_state!

    respond_to do |format|
      format.turbo_stream { head :ok }
      format.html { redirect_back(fallback_location: chat_path(@message.chat)) }
    end
  rescue WahaClient::Error => e
    redirect_back(fallback_location: chat_path(@message.chat), alert: "Failed to unpin message: #{e.message}")
  end
end