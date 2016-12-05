require 'sinatra'
require './zip-helper'
require 'data_mapper'
require 'digest/sha2'
require './user-helper'
require 'csv'

enable :sessions

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
  if logged_in?
    @user = User.first(:hashed_password => session[:user])
  end
  @sites = create_sites_list
  erb :vote
end

get '/results' do
  if logged_in?
    @user = User.first(:hashed_password => session[:user])
  end
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
    session[:flash] = 'Upload successful!'
  elsif params.has_key?('sites')
    if params['sites'][:type] == 'application/zip'
      File.open('public/uploads/sites/' + params['sites'][:filename], 'w') do |f|
        f.write(params['sites'][:tempfile].read)
      end
      unzip_file('public/uploads/sites/' + params['sites'][:filename], 'public/uploads/sites/')
    end
    session[:flash] = 'Upload successful!'
  end
  redirect '/upload'
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
      redirect '/login'
    end
  else
    session[:flash] = 'Incorrect Password'
    redirect '/login'
  end

  redirect '/account'
end

post '/user/logout' do
  session[:user] = nil
  session[:flash] = 'You are now logged out!'
  redirect '/'
end

get '/results/download' do
  headers['Content-Disposition'] = "attachment; filename = results.csv"
  send_file 'public/results/results.csv'
  redirect '/results'
end