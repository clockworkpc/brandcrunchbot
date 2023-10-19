Rails.application.routes.draw do
  devise_for :users
  root to: 'home#index'

  resources :oauth_sessions
  get '/oauth2callback', to: 'oauth_sessions#create'

  # devise_scope :user do
  #   # Redirests signing out users back to sign-in
  #   get 'users', to: 'devise/sessions#new'
  # end

  # resources :users

  # devise_for :users, controllers: { registrations: 'registrations' }
end
