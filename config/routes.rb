Rails.application.routes.draw do
  resources :feeds do
    member do
      resources :entries, only: [:index, :show]
      post    '/subscribe',   to: 'feed_subscriptions#subscribe'
      delete  '/unsubscribe',   to: 'feed_subscriptions#unsubscribe'
    end
  end

  resources :feeds
  #root 'feeds#index'
  
  root 'static_pages#home'

  get 		'/help', 	to: 'static_pages#help'
  get 		'/about', 	to: 'static_pages#about'
  get 		'/contact', to: 'static_pages#contact'
  get 		'/signup', 	to: 'users#new'
  get     '/dashboard', to: 'users#dashboard'
  get 		'/login', 	to: 'sessions#new'
  post 		'/login', 	to: 'sessions#create'
  delete 	'/logout',	to: 'sessions#destroy'
  resources :users
end
