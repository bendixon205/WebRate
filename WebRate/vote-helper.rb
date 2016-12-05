DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/users.db")
DataMapper::Property.required(true)

class Vote
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :unique => true
  property :vote1, String
  property :vote2, String
  property :vote3, String

end