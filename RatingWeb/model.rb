require "sinatra"
require "data_mapper"
require "digest/sha2"

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
		randdompass= Random.new
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
	erb :index
end

post "/user/authenticate" do
	user = User.first(:name => params[:name])
	
	if !user
		session[:flash] = "User doesn't exist"
		redirect "/"
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
	
	redirect "/"
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
		redirect "/"
	else
		session[:flash] = "Error Singing Up"
		redirect "/"
	end
	
	
end

DataMapper.auto_upgrade!

