require "bundler/inline"
require "openssl"
require 'absolute_time'

gemfile do
    source "http://rubygems.org"

    gem "sinatra-contrib"
    gem "rackup"
    gem "webrick"
    gem "mysql2"
    gem "faraday"
end

require "json"
require 'sinatra'
require "mysql2"
require "faraday"
require 'securerandom'
require_relative "auth.rb"
require_relative "env.rb"

set :port, 4567
set :bind, '0.0.0.0'
enable :sessions

client = Mysql2::Client.new(:host => "localhost", :username => "bot", :password => "joel")
client.query("USE joelScan;")

#connect to my ntfy server
NTFYDerver = Faraday.new(url: "https://ntfy.venorrak.dev") do |conn|
    conn.request :url_encoded
end

#-----------------------------------------------------------------------#
#------------------------------FUNCTIONS--------------------------------#
#-----------------------------------------------------------------------#

def sendNotif(message, title)
    subject = "290ba96bcabd3d74552ca9d39482cc3a"
    rep = NTFYDerver.post("/#{subject}") do |req|
        req.headers["host"] = "ntfy.venorrak.dev"
        req.headers["Priority"] = "5"
        req.headers["Title"] = title
        req.body = message.to_json
    end
    p rep.body
end

def guard!
    auth_required = [
      401,
      {
        "Content-Type" => "application/json",
      },
      "Invalid credentials".to_json
    ]
  
    # HALT interrompt IMMEDIATEMENT la requête et retourne le resultat
    halt auth_required unless authorized?
end
  
def authorized?
    auth ||=  Rack::Auth::Basic::Request.new(request.env) 
    # request.env est disponible car on est dans le block HELPERS
    p "session : #{session[:username]}"
    p "verified : #{session[:verified]}"
    if session[:username].nil?
        return unless auth.provided? && auth.basic? && auth.credentials
        username, password = auth.credentials
        $loginInfo = authenticate(username, password)
    end
end

def getUserRarity(name, client)
    nbOfUsersUnder = client.query("SELECT COUNT(*) AS 'nbOfUsersUnder' FROM joels WHERE count <= (SELECT count FROM joels WHERE user_id = (SELECT id FROM users WHERE name = '#{name}'))").first
    nbOfUsersUnder = nbOfUsersUnder["nbOfUsersUnder"]
    nbOfUsers = client.query("SELECT COUNT(*) AS 'nbOfUsers' FROM joels").first["nbOfUsers"]
    return ((nbOfUsersUnder.to_f / nbOfUsers.to_f) * 100).round(4)
end

def getChannelRarity(name, client)
    nbOfChannelsUnder = client.query("SELECT COUNT(*) AS 'nbOfChannelsUnder' FROM channelJoels WHERE count <= (SELECT count FROM channelJoels WHERE channel_id = (SELECT id FROM channels WHERE name = '#{name}'))").first
    nbOfChannelsUnder = nbOfChannelsUnder["nbOfChannelsUnder"]
    nbOfChannels = client.query("SELECT COUNT(*) AS 'nbOfChannels' FROM channelJoels").first["nbOfChannels"]
    return ((nbOfChannelsUnder.to_f / nbOfChannels.to_f) * 100).round(4)
end

def getChannelHistory(name, client, limit)
    history = []
    channel_id = client.query("SELECT id FROM channels WHERE name = '#{name}'").first["id"]
    client.query("SELECT streamDate, count FROM streamJoels WHERE channel_id = #{channel_id} ORDER BY streamDate ASC LIMIT #{limit}").each do |row|
        data = {
            "date": row["streamDate"],
            "count": row["count"]
        }
        history << data
    end
    return history
end

def rebootSQLconnection()
    client = nil
    sleep(1)
    client = Mysql2::Client.new(:host => "localhost", :username => "bot", :password => "joel")
    client.query("USE joelScan;")
    p "rebooting SQL connection"
end

#-----------------------------------------------------------------------#
#------------------------------HTML ROUTES------------------------------#
#-----------------------------------------------------------------------#

get '/' do
    return send_file "html/home.html"
end

get '/portfolio' do
    return send_file "html/portfolio.html"
end

get '/joels/users' do
    if params[:name] != nil
        return send_file "html/user.html"
    else
        return send_file "html/userStats.html"
    end
end

get '/joels/channels' do
    if params[:name] != nil
        return send_file "html/channel.html"
    else
        return send_file "html/channelStats.html"
    end
end

get '/manage' do
    guard!
    return send_file "html/manage.html"
end

get '/login' do
    return send_file "html/login.html"
end

#-----------------------------------------------------------------------#
#------------------------------ACTIONS ROUTES---------------------------#
#-----------------------------------------------------------------------#

get '/login/status' do
    if !session[:username].nil?
        return [
            200,
            { "Content-Type" => "application/json" },
            {status: "connected"}.to_json
        ]
    else
        return [
            401,
            { "Content-Type" => "application/json" },
            {status: "not connected"}.to_json
        ]
    end
end

post '/login' do
    guard!
    if !session
        return [
            401,
            { "Content-Type" => "application/json" },
            "bad credentials"
        ]
    else
        p "login info : #{$loginInfo}"
        session[:username] = $loginInfo[:username]
        p "session : #{session[:username]}"
        return [
            200,
            { "Content-Type" => "application/json" },
            "connected"
        ]
    end
end

get '/logout' do
    session.clear
    return [
      200,
      { "Content-Type" => "application/json" },
      {status: "logged out"}.to_json
    ]
end

post '/login/sendCode' do
    code = SecureRandom.alphanumeric(6).upcase
    session[:code] = code
    p session[:code]
    sendNotif("Your code is : #{code}", "2FA code")
    sleep(60)
    p "code expired verif : #{session[:verified]}"
    unless session[:verified] == true
        session.clear
        p "session cleared"
        return [
            401,
            { "Content-Type" => "application/json" },
            {status: "not connected"}.to_json
        ]
    end
    return [
        200,
        { "Content-Type" => "application/json" },
        {status: "connected"}.to_json
    ]
end

post '/login/verify' do
    data = JSON.parse(request.body.read)
    p data
    p session[:code]
    if data["code"].upcase == session[:code]

        session[:verified] = true
        p "verified"
        p session[:verified]
        p session[:username]
        p session[:code]
        return [
            200,
            { "Content-Type" => "application/json" },
            {status: "connected"}.to_json
        ]
    else
        p "wrong 2fa"
        session.clear
        return [
            401,
            { "Content-Type" => "application/json" },
            {status: "not connected"}.to_json
        ]
    end
end

get '/pictures/:filename' do
    p params[:filename]
    send_file "#{__dir__}/pictures/#{params[:filename]}"
end

#-----------------------------------------------------------------------#
#--------------------------------- API ---------------------------------#
#-----------------------------------------------------------------------#

get '/api/joels/users' do
    listUsers = Array.new
    way = params[:way]
    if way != "ASC" && way != "DESC" && way != nil
        return [
            400,
            { "Content-Type" => "application/json" },
            {error: "bad request"}.to_json
        ]
    else
        begin
            if params[:sort] == nil
                client.query("SELECT users.name, users.creationDate AS 'date', joels.count FROM users join joels on joels.user_id = users.id").each do |row|
                    listUsers.push(row)
                end
            else
                if params[:sort] == "count"
                    client.query("SELECT users.name, users.creationDate AS 'date', joels.count FROM users join joels on joels.user_id = users.id ORDER BY IFNULL(joels.count, 0) #{way};").each do |row|
                        listUsers.push(row)
                    end
                elsif params[:sort] == "creationDate"
                    client.query("SELECT users.name, users.creationDate AS 'date', joels.count FROM users join joels on joels.user_id = users.id ORDER BY users.creationDate #{way};").each do |row|
                        listUsers.push(row)
                    end
                elsif params[:sort] == "name"
                    client.query("SELECT users.name, users.creationDate AS 'date', joels.count FROM users join joels on joels.user_id = users.id ORDER BY users.name #{way};").each do |row|
                        listUsers.push(row)
                    end
                end
            end
            return [
                200,
                { "Content-Type" => "application/json" },
                listUsers.to_json
            ]
        rescue
            rebootSQLconnection()
            return [
                500,
                { "Content-Type" => "application/json" },
                {error: "internal server error"}.to_json
            ]
        end
    end
end

get '/api/joels/channels' do
    listChannels = Array.new
    way = params[:way]
    if way != "ASC" && way != "DESC" && way != nil
        return [
            400,
            { "Content-Type" => "application/json" },
            {error: "bad request"}.to_json
        ]
    else
        begin
            if params[:sort] == nil
                client.query("SELECT channels.name, channels.creationDate AS 'date', channelJoels.count FROM channels join channelJoels on channelJoels.channel_id = channels.id").each do |row|
                    listChannels.push(row)
                end
            else
                if params[:sort] == "count"
                    client.query("SELECT channels.name, channels.creationDate AS 'date', channelJoels.count FROM channels join channelJoels on channelJoels.channel_id = channels.id ORDER BY IFNULL(channelJoels.count, 0) #{way};").each do |row|
                        listChannels.push(row)
                    end
                elsif params[:sort] == "creationDate"
                    client.query("SELECT channels.name, channels.creationDate AS 'date', channelJoels.count FROM channels join channelJoels on channelJoels.channel_id = channels.id ORDER BY channels.creationDate #{way};").each do |row|
                        listChannels.push(row)
                    end
                elsif params[:sort] == "name"
                    client.query("SELECT channels.name, channels.creationDate AS 'date', channelJoels.count FROM channels join channelJoels on channelJoels.channel_id = channels.id ORDER BY channels.name #{way};").each do |row|
                        listChannels.push(row)
                    end
                end
            end
            return [
                200,
                { "Content-Type" => "application/json" },
                listChannels.to_json
            ]
        rescue
            rebootSQLconnection()
            return [
                500,
                { "Content-Type" => "application/json" },
                {error: "internal server error"}.to_json
            ]
        end
    end
end

get '/api/joels/users/:name' do
    begin
        user = client.query("SELECT users.name, users.creationDate AS 'date', joels.count, users.pfp_id, users.bgp_id, users.twitch_id FROM users join joels on joels.user_id = users.id WHERE users.name = '#{params[:name]}';").first rescue nil
        
        if user == nil
            return [
                404,
                { "Content-Type" => "application/json" },
                {error: "user not found"}.to_json
            ]
        else
            pfp = client.query("SELECT url FROM pictures WHERE id = #{user["pfp_id"]};").first["url"]
            bgp = client.query("SELECT url FROM pictures WHERE id = #{user["bgp_id"]};").first["url"]
            data = {
                "name": user["name"],
                "date": user["date"],
                "count": user["count"],
                "pfp": pfp,
                "bgp": bgp,
                "twitch_id": user["twitch_id"],
                "rarity": getUserRarity(user["name"], client)
            }
            return [
                200,
                { "Content-Type" => "application/json" },
                data.to_json
            ]
        end
    rescue
        rebootSQLconnection()
        return [
            500,
            { "Content-Type" => "application/json" },
            {error: "internal server error"}.to_json
        ]
    end
end

get '/api/joels/channels/:name' do
    begin
        channel = client.query("SELECT channels.name, channels.creationDate AS 'date', channelJoels.count FROM channels join channelJoels on channelJoels.channel_id = channels.id WHERE channels.name = '#{params[:name]}';").first
        if channel == nil
            return [
                404,
                { "Content-Type" => "application/json" },
                {error: "channel not found"}.to_json
            ]
        else
            data = {
                "name": channel["name"],
                "date": channel["date"],
                "count": channel["count"],
                "rarity": getChannelRarity(channel["name"], client),
                "history": getChannelHistory(channel["name"], client, 10)
            }
            return [
                200,
                { "Content-Type" => "application/json" },
                data.to_json
            ]
        end
    rescue
        rebootSQLconnection()
        return [
            500,
            { "Content-Type" => "application/json" },
            {error: "internal server error"}.to_json
        ]
    end
end

get '/api/joels/channels/history/:name' do
    limit = params[:limit] || 10
    channel_name = nil
    channel_id = nil
    begin
        client.query("SELECT name, id FROM channels WHERE name = '#{params[:name]}' LIMIT 1").each do |row|
            channel_name = row["name"]
            channel_id = row["id"]
        end
        if channel_name == nil
            return [
                404,
                { "Content-Type" => "application/json" },
                {error: "channel not found"}.to_json
            ]
        else
            history = getChannelHistory(channel_name, client, limit)
            return [
                200,
                { "Content-Type" => "application/json" },
                history.to_json
            ]
        end
    rescue
        return [
            500,
            { "Content-Type" => "application/json" },
            {error: "internal server error"}.to_json
        ]
    end
end

#-----------------------------------------------------------------------#
#--------------------------------OTHER----------------------------------#
#-----------------------------------------------------------------------#

Thread.start do
    loop do
        sleep(60)
        client.query("SELECT 1")
    end
end