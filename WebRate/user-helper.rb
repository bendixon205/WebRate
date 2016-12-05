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
