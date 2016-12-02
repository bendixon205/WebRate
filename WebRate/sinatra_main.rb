require 'sinatra'
require './zip-helper'
require 'sinatra/reloader' if development?

# display the home layout
get '/' do
  erb :home
end

get '/login' do
  erb :login
end

# post '/login' do
#   if params[:username] == settings.username && params[:password] == settings.password
#     session[:admin] = true
#     redirect to('/vote')
#   else
#     erb :vote
#   end
# end

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

post '/upload' do
  File.open('public/uploads/sites/' + params['sites'][:filename], 'w') do |f|
    f.write(params['sites'][:tempfile].read)
  end
  unzip_file('public/uploads/sites/' + params['sites'][:filename], 'public/uploads/sites/')
  erb :upload
end

# 404 page
not_found do
  erb :not_found
end
