require 'sinatra/base'
require 'mongo'
require 'uri'
require './lib/user'
class App < Sinatra::Base
  set :sessions => true
  uri = ENV["MONGODB_URI"] != nil ? ENV["MONGODB_URI"] : "mongodb://127.0.0.1:27017/mydb"
  client = Mongo::Client.new(uri)

  # A password for use on locked pages.
  lockword = ENV["LOCKWORD"] != nil ? ENV["LOCKWORD"] : "locked"

  register do
    def auth (type)
      condition do
        redirect "/login" unless send("is_#{type}?")
      end
    end
  end

  helpers do
    def is_user?
      @user != nil
    end
    def follow_then_to
      if params["then_to"] == nil || params["then_to"] == ""
        redirect to "/"
      else
        redirect to params["then_to"]
      end
    end
    def locked!
      return if unlocked?
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end

    def unlocked?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['admin', 'LOCKWORD']
    end
  end

  before do
    @user = User.by_sessionid(client, session[:user_id])
  end

  get "/" do
    haml :home
  end

  get "/protected", :auth => :user do
    "Authenticated!"
  end

  get "/login" do
    haml :login
  end

  post "/login/auth" do
    data = User.login(client, params["username"], params["password"]) # User.authenticate(params).id
    puts "FOO"
    if data.is_a? String
      redirect to ("/login?then_to=" + params["then_to"] + "&error=" + URI.escape(data))
    else
      session[:user_id] = data
      follow_then_to
    end
  end

  get "/register" do
    locked!
    "Hello!"
  end

  get "/logout" do
    session[:user_id] = nil
    follow_then_to
  end
  run!
end
