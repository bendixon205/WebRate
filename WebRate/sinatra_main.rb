require 'sinatra'
require './zip-helper'
require 'data_mapper'
require 'digest/sha2'
require 'csv'

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

  property :id, Serial
  property :name, String
  property :role, String
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

get '/' do
  if logged_in?
    @user = User.first(:hashed_password => session[:user])
  end
  erb :home
end

get '/login' do
  if logged_in?
    @user = User.first(:hashed_password => session[:user])
    redirect '/account'
  end
  erb :login
end

get '/logout' do
  session.clear
  redirect to('/login')
end

get '/account' do
  if logged_in?
    @user = User.first(:hashed_password => session[:user])
  end
  erb :account
end

get '/vote' do
  @sites = create_sites_list
  erb :vote
end

get '/results' do
  erb :results
end

get '/upload' do
  if logged_in?
    @user = User.first(:hashed_password => session[:user])
  end
  erb :upload
end

post '/upload' do
  if params.has_key?('users')
    if params['users'][:type] == 'text/csv'
      File.open('public/uploads/' + params['users'][:filename], 'w') do |f|
        f.write(params['users'][:tempfile].read)
      end
      DataMapper.finalize
      CSV.foreach('public/uploads/' + params['users'][:filename]) do |row|
        salt = get_salt
        salt.encode!('UTF-8', :invalid=>:replace, :undef=>:replace, :replace=>'?')
        hashed_password = hash_password(row[1], salt)
        user = User.new(:name => row[0], :salt => salt, :hashed_password => hashed_password, :role => row[2])
        user.save
      end
      DataMapper.auto_upgrade!
    end
  elsif params.has_key?('sites')
    if params['sites'][:type] == 'application/zip'
      File.open('public/uploads/sites/' + params['sites'][:filename], 'w') do |f|
        f.write(params['sites'][:tempfile].read)
      end
      unzip_file('public/uploads/sites/' + params['sites'][:filename], 'public/uploads/sites/')
    end
  end
  erb :upload
end

# 404 page
not_found do
  erb :not_found
end

post '/user/authenticate' do
  user = User.first(:name => params[:name])

  if !user
    session[:flash] = "User doesn't exist"
    redirect '/login'
  end

  authenticated = user.authenticate(params[:password])

  if authenticated
    if user.save
      session[:user] = user.hashed_password
    else
      session[:flash] = 'Sorry! Please try to Log in again!'
    end
  else
    session[:flash] = 'Incorrect Password'
  end

  redirect '/account'
end

post '/user/logout' do
  session[:user] = nil
  session[:flash] = 'You are now logged out!'
  redirect '/'
end

get '/signup' do
  erb :signup
end

post '/user/create' do
  user = User.first(:name => params[:name])

  if user
    session[:flash] = 'Username taken. Try  again!'
    redirect '/signup'
  end

  if !params[:password].eql?(params[:password2])
    session[:flash] = 'Password Does Not Match!'
    redirect '/signup'
  end

  salt = get_salt
  hashed_password = hash_password(params[:password], salt)
  user = User.new(:name => params[:name], :salt => salt,:hashed_password => hashed_password,)

  if user.save
    session[:flash] = 'Great! You have Signed Up!'
    session[:user] = user.hashed_password
    redirect '/signup'
  else
    session[:flash] = 'Error Singing Up'
    redirect '/signup'
  end


end