GifVault::Application.routes.draw do
  root to: 'gif#cool'

  get '/login' => 'sessions#new'
  post '/login' => 'sessions#create'
  get '/logout' => 'sessions#destroy'


  get '/signup' => 'users#new'
  post '/users' => 'users#create'
end