Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  post "/waha/sessions", to: "waha_sessions#create"
  get  "/waha/qr",      to: "waha_sessions#qr"
  get "/waha/sessions", to: "waha_sessions#index"
  delete "/waha/sessions/:id", to: "waha_sessions#destroy"
  # The `qr` action responds with either HTML or PNG depending on the requested
  # format, so a separate `qr_png` route is no longer necessary.

  post "/waha/webhooks", to: "waha_webhooks#receive"

  resources :chats, only: [:index, :show] do
    resources :messages, only: :create do
      member do
        patch :pin, to: "messages#pin"
        patch :unpin, to: "messages#unpin"
      end
    end

    # Typing indicator endpoints
    member do
      post :typing, to: "chats#start_typing"
      post :typing_stop, path: "typing/stop", to: "chats#stop_typing"
      patch :pin, to: "chats#pin"
      patch :unpin, to: "chats#unpin"
      post :sync_pin_states, to: "chats#sync_pin_states"
    end
  end

  resources :waha_events, only: :index

  # Link chats filtered by session
  get "/waha/sessions/:waha_session_id/chats", to: "chats#index", as: :waha_session_chats

  # Proxy WAHA file requests to the WAHA service
  get "/api/files/*path", to: "waha_files#proxy"

  # Product Management
  resources :products do
    resources :product_variants, path: :variants, as: :variants do
      member do
        post :activate
        post :deactivate
        post :duplicate
      end
    end
    
    member do
      post :activate
      post :deactivate
      post :duplicate
    end
    
    collection do
      get :categories
      post :bulk_import
      get :export
      get :low_stock
    end
  end

  # Inventory Management
  resources :inventory_lots, path: 'inventory/lots' do
    collection do
      get :expiring
      post :bulk_receive
    end
  end

  resources :inventory_adjustments, path: 'inventory/adjustments' do
    collection do
      get :summary
      post :bulk_create
    end
  end

  # Sourcing & Purchasing
  resources :sourcing_orders, path: 'sourcing' do
    member do
      patch :submit
      patch :approve
      patch :receive
      patch :cancel
    end
    
    collection do
      get :pending
      get :approved
      get :received
    end
  end

  # Orders management
  resources :orders do
    collection do
      get :search_products
      post :calculate_shipping
      post :parse_google_maps_link
    end
  end

  # Defines the root path route ("/")
  root "home#index"
end
