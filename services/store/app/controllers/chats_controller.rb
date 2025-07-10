class ChatsController < ApplicationController
  def index
    if params[:waha_session_id].present?
      @waha_session = WahaSession.find(params[:waha_session_id])
      @chats = @waha_session.chats.order(last_message_at: :desc)
    else
      @chats = Chat.order(last_message_at: :desc).limit(200)
    end
  end

  def show
    @chat = Chat.find(params[:id])

    # Load chats for the list sidebar – either scoped to the WAHA session or global
    if params[:waha_session_id].present?
      @waha_session = WahaSession.find(params[:waha_session_id])
      @chats = @waha_session.chats.order(last_message_at: :desc)
    else
      @chats = Chat.order(last_message_at: :desc).limit(200)
    end

    # Fallback to the chat's session so the UI can highlight it even without the param
    @waha_session ||= @chat.waha_session

    # Load all WAHA sessions so we can show them in the thin left-most sidebar
    @sessions = WahaSession.order(:name)

    @messages = @chat.messages.order(:created_at)
  end
end