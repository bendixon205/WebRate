require 'sinatra'
require './zip-helper'
require 'data_mapper'
require 'digest/sha2'

enable :sessions

#our database name users.db
DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/users.db")
DataMapper::Property.required(true)

#only way to get access to helper method
module PasswordHasher
  def hash_password(password, salt)
    Digest::SHA2.hexdigest(password+salt)
  end
end

include PasswordHasher

class User
  include DataMapper::Resource
  include PasswordHasher

  #validations???? NOT SURE if we need it guy??
  #CHECK Length of password
  #Can't have same username

  property :id, Serial
  property :name, String
  property :salt, String, :length => 32
  property :hashed_password, String, :length => 64



  def authenticate(password)
    if (hash_password(password, salt)).eql?(hashed_password)
      true
    else
      false
    end
  end
end

#HELPER METHOD

helpers do
  def logged_in?
    if session[:user]
      true
    else
      false
    end
  end

  def get_salt
    randompass= Random.new
    Array.new(User.salt.length){ randompass.rand(40...140).chr }.join
  end


  def display_flash(key)
    if session[key]
      flash = session[key]
      session[key] = false
      flash
    end
  end
end

get "/" do
  if logged_in?
    @user = User.first(:hashed_password => session[:user])
  end
  erb :home
end

# display the home layout
#get '/' do
#  erb :home
#end

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

post "/user/authenticate" do
  user = User.first(:name => params[:name])

  if !user
    session[:flash] = "User doesn't exist"
    redirect "/login"
  end

  authenticated = user.authenticate(params[:password])

  if authenticated
    if user.save
      session[:user] = user.hashed_password
    else
      session[:flash] = "Sorry! Please try to Log in again!"
    end
  else
    session[:flash] = "Incorrect Password"
  end

  redirect "/login"
end

post "/user/logout" do
  session[:user] = nil
  session[:flash] = "You are now logged out!"
  redirect "/"
end

get "/signup" do
  erb :signup
end

post "/user/create" do
  user = User.first(:name => params[:name])

  if user
    session[:flash] = "Username taken. Try  again!"
    redirect "/signup"
  end

  if !params[:password].eql?(params[:password2])
    session[:flash] = "Password Does Not Match!"
    redirect "/signup"
  end

  salt = get_salt
  hashed_password = hash_password(params[:password], salt)
  user = User.new(:name => params[:name], :salt => salt,:hashed_password => hashed_password,)

  if user.save
    session[:flash] = "Great! You have Signed Up!"
    session[:user] = user.hashed_password
    redirect "/signup"
  else
    session[:flash] = "Error Singing Up"
    redirect "/signup"
  end


end

DataMapper.auto_upgrade!
