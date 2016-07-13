require 'sinatra/base'
class App < Sinatra::Base
  set :sessions => true

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
  end

  before do
    @user = session[:user_id] != nil ? {:username => session[:user_id]} : nil # Get user via session[:user_id]
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
    session[:user_id] = params["username"] # User.authenticate(params).id
    follow_then_to
  end

  get "/logout" do
    session[:user_id] = nil
    follow_then_to
  end
  run!
end
