require 'sinatra'
require 'sanitize'
require './zip-helper'
require 'data_mapper'
require 'digest/sha2'
require './user-helper'
require 'csv'
require './vote-helper'

enable :sessions
DataMapper.finalize
DataMapper.auto_upgrade!

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

post '/vote' do
  if logged_in?
    @user = User.first(:hashed_password => session[:user])
  end
  session[:flash] = ""

  params['vote-1'] = Sanitize.clean params['vote-1']
  params['vote-2'] = Sanitize.clean params['vote-2']
  params['vote-3'] = Sanitize.clean params['vote-3']

  vote = Vote.first(:name => @user.name)
  if vote
    session[:flash] += "Error: vote already submitted. "
  end
  if params['vote-1'] == params['vote-2'] or params['vote-1'] == params['vote-2'] or params['vote-2'] == params['vote-3']
    session[:flash] += "Error: cannot vote for the same site twice. "
  end
  if params['vote-1'].empty? or params['vote-2'].empty? or params['vote-3'].empty?
    session[:flash] += "Error: must submit three votes. "
  end

  # if there is an error, redirect here, before submitting
  if !session[:flash].empty?
    redirect '/vote'
  end

  vote = Vote.new(:name => @user.name, :vote1 => params['vote-1'], :vote2 => params['vote-2'], :vote3 => params['vote-3'])

  if vote.save
    puts 'saved'
    session[:flash] = "Your vote has been submitted"
  else
    puts 'not saved'
    session[:flash] = "Error: vote could not be submitted"
  end

  DataMapper.auto_upgrade!
  redirect '/vote'
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
    if params['users'][:type] == 'text/csv' or params['users'][:type] == 'application/vnd.ms-excel'
      File.open('public/uploads/' + params['users'][:filename], 'wb') do |f|
        f.write(params['users'][:tempfile].read)
      end
      CSV.foreach('public/uploads/' + params['users'][:filename]) do |row|
        row.each do |r|
          r = Sanitize.clean r
        end
        salt = get_salt
        salt.encode!('UTF-8', :invalid=>:replace, :undef=>:replace, :replace=>'?')
        hashed_password = hash_password(row[1], salt)
        user = User.new(:name => row[0], :salt => salt, :hashed_password => hashed_password, :role => row[2])
        begin
          user.save
        rescue

        end
      end
      DataMapper.auto_upgrade!
    end
    session[:flash] = 'Upload successful!'
  elsif params.has_key?('sites')
    if params['sites'][:type] == 'application/zip' or params['sites'][:type] == 'application/octet-stream'
      File.open('public/uploads/sites/' + params['sites'][:filename], 'wb') do |f|
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
  params[:name] = Sanitize.clean params[:name]
  params[:password] = Sanitize.clean params[:password]
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
  CSV.open('public/results/results.csv', 'w') do |csv|
    votes = Vote.all.each do |v|
      csv << [v.name,v.vote1,v.vote2,v.vote3]
    end
  end

  headers['Content-Disposition'] = "attachment; filename = results.csv"
  send_file 'public/results/results.csv'
  redirect '/results'
end