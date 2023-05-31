Rails.application.routes.draw do
  root to: 'welcome#index'

  devise_scope :user do
    # Redirests signing out users back to sign-in
    get 'users', to: 'devise/sessions#new'
  end

  resources :oauth_sessions
  resources :users

  get '/oauth2callback', to: 'oauth_sessions#create'

  devise_scope :user do
    # Redirests signing out users back to sign-in
    get 'users', to: 'devise/sessions#new'
  end

  devise_for :users, controllers: { registrations: 'registrations' }
end
