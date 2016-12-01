require 'sinatra'


configure do
  enable :sessions
  set :username, 'username'
  set :password, 'password'
end

# display the home layout
get '/' do
  erb :home
end

get '/login' do
  erb :login
end

post '/login' do
  if params[:username] == settings.username && params[:password] == settings.password
    session[:admin] = true
    redirect to('/vote')
  else
    slim :login
  end
end

get '/logout' do
  session.clear
  redirect to('/login')
end

get '/account' do
  erb :account
end

get '/vote' do
  erb :vote
end

get '/results' do
  erb :results
end

get '/upload' do
  erb :upload
end
# get '/:site' do
#   @site = params['site']
#   File.read(File.join('public', 'site.html'))
# end

# 404 page
not_found do
  erb :not_found
end
