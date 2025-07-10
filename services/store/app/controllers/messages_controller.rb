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
end