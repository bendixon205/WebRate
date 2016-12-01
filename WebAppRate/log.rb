require 'dm-core'
require 'dm-migrations'

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/development.db")


class User
  include DataMapper::Resource
  property :id, Serial
  property :username, Text
  property :password, Text
  property :salt , String
end

DataMapper.finalize()