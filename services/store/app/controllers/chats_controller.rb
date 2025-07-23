class ChatsController < ApplicationController
  # Skip CSRF for pin/unpin actions since they're called via AJAX
  skip_before_action :verify_authenticity_token, only: [:pin, :unpin]
  def index
    if params[:waha_session_id].present?
      @waha_session = WahaSession.find(params[:waha_session_id])
      # Refresh chats overview to ensure last_message_at is up-to-date without fetching every message
      @waha_session.sync_chats_overview!
      # Refresh session profile picture
      @waha_session.refresh_profile_picture!
      @chats = @waha_session.chats
    else
      # Refresh overview for all sessions (usually few) to keep timestamps fresh
      WahaSession.find_each { |s| s.sync_chats_overview! }
      @chats = Chat.non_broadcast
    end

    # Stable, WhatsApp-like sorting: pinned first, then latest message sent_at (or created_at), fallback to last_message_at, then chat id
    @chats = @chats.left_joins(:messages)
                   .select('chats.*, COALESCE(MAX(messages.sent_at), MAX(messages.created_at), chats.last_message_at, chats.created_at) AS sort_time')
                   .group('chats.id')
                   .order('chats.pinned_at DESC NULLS LAST, sort_time DESC, chats.id DESC')
                   .limit(200)

    # Mark all incoming, unread messages as read for all visible chats
    Message.where(chat_id: @chats.map(&:id)).incoming.where(read_at: nil).update_all(read_at: Time.current)
  end

  def show
    @chat = Chat.find(params[:id])

    # Sync messages from WAHA to ensure we have all messages (both incoming and outgoing)
    @chat.sync_messages_from_waha!

    # Also refresh chats overview for the associated WAHA session so timestamps stay accurate
    if @chat.waha_session
      @chat.waha_session.sync_chats_overview!
    end

    # Mark all incoming, unread messages as read
    @chat.messages.incoming.where(read_at: nil).update_all(read_at: Time.current)

    # Load chats for the list sidebar – either scoped to the WAHA session or global
    if params[:waha_session_id].present?
      @waha_session = WahaSession.find(params[:waha_session_id])
      @chats = @waha_session.chats
    else
      @chats = Chat.non_broadcast
    end

    # Stable, WhatsApp-like sorting for sidebar: pinned first, then by latest message
    @chats = @chats.left_joins(:messages)
                   .select('chats.*, COALESCE(MAX(messages.sent_at), MAX(messages.created_at), chats.last_message_at, chats.created_at) AS sort_time')
                   .group('chats.id')
                   .order('chats.pinned_at DESC NULLS LAST, sort_time DESC, chats.id DESC')
                   .limit(200)

    # Fallback to the chat's session so the UI can highlight it even without the param
    @waha_session ||= @chat.waha_session

    # Load all WAHA sessions so we can show them in the thin left-most sidebar
    @sessions = WahaSession.order(:name)

    # Refresh profile pictures for all sessions
    @sessions.each(&:refresh_profile_picture!)

    # Order messages chronologically using their actual sent time when available
    @messages = @chat.messages.order(Arel.sql("COALESCE(sent_at, created_at) ASC"))
  end

  def start_typing
    chat = Chat.find(params[:id])
    WahaClient.new.start_typing(phone_number: chat.wa_id.delete_suffix("@c.us"))
    head :accepted
  end

  def stop_typing
    chat = Chat.find(params[:id])
    WahaClient.new.stop_typing(phone_number: chat.wa_id.delete_suffix("@c.us"))
    head :accepted
  end

  def pin
    @chat = Chat.find(params[:id])
    @chat.pin!
    redirect_back(fallback_location: chat_path(@chat))
  end

  def unpin
    @chat = Chat.find(params[:id])
    @chat.unpin!
    redirect_back(fallback_location: chat_path(@chat))
  end

  def sync_pin_states
    @chat = Chat.find(params[:id])
    @chat.sync_pin_states!

    respond_to do |format|
      format.turbo_stream { head :ok }
      format.html { redirect_back(fallback_location: chat_path(@chat), notice: "Pin states synced") }
    end
  end
end