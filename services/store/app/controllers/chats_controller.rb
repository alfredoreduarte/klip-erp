class ChatsController < ApplicationController
  def index
    @chats = Chat.order(last_message_at: :desc).limit(200)
  end

  def show
    @chat = Chat.find(params[:id])
    @messages = @chat.messages.order(:created_at)
  end
end