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
  # The `qr` action responds with either HTML or PNG depending on the requested
  # format, so a separate `qr_png` route is no longer necessary.

  post "/waha/webhooks", to: "waha_webhooks#receive"

  resources :chats, only: [:index, :show] do
    resources :messages, only: :create
  end

  resources :waha_events, only: :index

  # Link chats filtered by session
  get "/waha/sessions/:waha_session_id/chats", to: "chats#index", as: :waha_session_chats

  # Defines the root path route ("/")
  root "home#index"
end
