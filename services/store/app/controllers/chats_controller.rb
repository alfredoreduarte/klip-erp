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
    @messages = @chat.messages.order(:created_at)
  end
end