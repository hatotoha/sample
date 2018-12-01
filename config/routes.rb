Rails.application.routes.draw do
  get 'users/new'

  root 'static_pages#home'
  # 次は7.4から

  get '/help', to: 'static_pages#help'
  get '/about', to: 'static_pages#about'
  get '/contact', to: 'static_pages#contact'

  get '/signup', to: 'users#new' # get '/new', to: 'users#new', as: 'signup'
  post '/signup',  to: 'users#create'

  resources :users

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
