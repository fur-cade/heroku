require 'digest'
require 'securerandom'
class Session
  def initialize client, id
    @client = client
    @id = id
    @username = client[:sessions].find(:_id => id)[0]
  end
  def id
    @id
  end
  def self.session_exists? sessionid
    client[:sessions].find(:_id => sessionid).count > 0
  end
  def self.spawn client, username
    result = client[:sessions].insert_one({
      :username => username
    })
    return Session.new client, result.id
  end
end
class User
  def initialize client, username
    @client = client
    @username = username
    @data = client[:users].find(:username => username)
  end
  def username
    @username
  end
  def self.create client, username, password
    return "A user with that name already exists." if client[:users].find(:username => username).length > 0
    if /^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$/ =~ username
      return "Usernames can only contain letters, numbers, and dashes, cannot start or end with a dash, and must be at least 2 characters long."
    end
    salt = SecureRandom.base64 64
    client[:users].insert_one({
      :username => username,
      :passhash => Digest::SHA256.hexdigest(password + salt),
      :salt => salt,
      :sessions => []
    })
    User.new client, username
  end

  def self.by_sessionid client, sessionid
    result = client[:sessions].find("$elemMatch" => { :sessionid => sessionid})
    result.count > 0 ? User.new(client, result[0][:username]) : nil
  end

  def self.login client, username, password
    error_invalid = "That username and password combination is invalid."
    data = client[:users].find(:username => username)
    if data.count > 0
      if Digest::SHE256.hexdigest(password + data[0][:salt]) == data[0][:passhash]
        user = User.new client, username
        return Session.spawn(client, username).id
      else
        return error_invalid
      end
    else
      return error_invalid
    end
  end
end
