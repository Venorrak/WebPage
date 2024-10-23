require "bundler/inline"
require "openssl"
require 'absolute_time'
require "net/http"
require "awesome_print"

gemfile do
    source "http://rubygems.org"
    gem "sinatra-contrib"
    gem "sinatra-cross_origin"
    gem "rackup"
    gem "webrick"
    gem "mysql2"
    gem "faraday"
end

require 'sinatra/cross_origin'
require "json"
require 'sinatra'
require "mysql2"
require "faraday"
require 'securerandom'
require_relative "env.rb"

set :port, 4567
set :bind, '0.0.0.0'
enable :sessions

#prod stuff
configure do
    enable :cross_origin
end
before do
    response.headers['Access-Control-Allow-Origin'] = '*'
end
set :protection, :except => :frame_options
set :protection, :except => [:json_csrf]
set :allow_origin, :any
set :allow_methods, [:get, :post, :options]
set :allow_credentials, true
set :max_age, "1728000"
set :expose_headers, ['Content-Type']
#don't touch

client = Mysql2::Client.new(:host => "localhost", :username => "bot", :password => "joel")
client.query("USE joelScan;")

#connect to my ntfy server
NTFYDerver = Faraday.new(url: "https://ntfy.venorrak.dev") do |conn|
    conn.request :url_encoded
end

# $api_token = ""
# $refresh_token = ""

# $tiltify_api = Faraday.new(url: "https://v5api.tiltify.com/") do |conn|
#     conn.request :url_encoded
# end

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

def getUserRarity(name, client)
    nbOfUsersUnder = client.query("SELECT COUNT(*) AS 'nbOfUsersUnder' FROM joels WHERE count <= (SELECT count FROM joels WHERE user_id = (SELECT id FROM users WHERE name = '#{name}'))").first
    nbOfUsersUnder = nbOfUsersUnder["nbOfUsersUnder"]
    nbOfUsers = client.query("SELECT COUNT(*) AS 'nbOfUsers' FROM joels").first["nbOfUsers"]
    return (100 - ((nbOfUsersUnder.to_f / nbOfUsers.to_f) * 100)).round(4)
end

def getChannelRarity(name, client)
    nbOfChannelsUnder = client.query("SELECT COUNT(*) AS 'nbOfChannelsUnder' FROM channelJoels WHERE count <= (SELECT count FROM channelJoels WHERE channel_id = (SELECT id FROM channels WHERE name = '#{name}'))").first
    nbOfChannelsUnder = nbOfChannelsUnder["nbOfChannelsUnder"]
    nbOfChannels = client.query("SELECT COUNT(*) AS 'nbOfChannels' FROM channelJoels").first["nbOfChannels"]
    return (100 - ((nbOfChannelsUnder.to_f / nbOfChannels.to_f) * 100)).round(4)
end

def getChannelHistory(channel_id, client, limit)
    history = []
    client.query("SELECT streamDate, count FROM streamJoels WHERE channel_id = #{channel_id} ORDER BY streamDate DESC LIMIT #{limit}").each do |row|
        data = {
            "date": row["streamDate"],
            "count": row["count"]
        }
        history << data
    end
    return history.reverse
end

def getUserHistory(user_id, client, limit)
    history = []
    client.query("SELECT streamJoels.streamDate, channels.name AS 'channel_name', streamUsersJoels.count FROM streamUsersJoels JOIN streamJoels ON streamJoels.id = streamUsersJoels.stream_id JOIN channels ON channels.id = streamJoels.channel_id WHERE streamUsersJoels.user_id = #{user_id} ORDER BY streamJoels.streamDate DESC LIMIT #{limit}").each do |row|
        data = {
            "date": row["streamDate"],
            "channel_name": row["channel_name"],
            "count": row["count"]
        }
        history << data
    end
    return history.reverse
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

#-----------------------------------------------------------------------#
#------------------------------ACTIONS ROUTES---------------------------#
#-----------------------------------------------------------------------#

get '/pictures/:filename' do
    p params[:filename]
    send_file "#{__dir__}/pictures/#{params[:filename]}"
end

get '/css/:filename' do
    return send_file "#{__dir__}/css/#{params[:filename]}"
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
        request = client.prepare("SELECT users.name, users.creationDate AS 'date', joels.count, users.pfp_id, users.bgp_id, users.twitch_id FROM users join joels on joels.user_id = users.id WHERE users.name = ?;")
        user = request.execute(params[:name]).first rescue nil
        
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
        request = client.prepare("SELECT channels.name, channels.id, channels.creationDate AS 'date', channelJoels.count FROM channels join channelJoels on channelJoels.channel_id = channels.id WHERE channels.name = ?;")
        channel = request.execute(params[:name]).first
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
                "history": getChannelHistory(channel["id"], client, 10)
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
    limit = params[:limit].to_i
    if limit == 0
        limit = 10
    end
    channel_id = nil
    begin
        request = client.prepare("SELECT id FROM channels WHERE name = ? LIMIT 1")
        request.execute(params[:name]).each do |row|
            channel_id = row["id"]
        end
        if channel_id == nil
            return [
                404,
                { "Content-Type" => "application/json" },
                {error: "channel not found"}.to_json
            ]
        else
            history = getChannelHistory(channel_id, client, limit)
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

get '/api/joels/users/history/:name' do
    limit = params[:limit].to_i
    if limit == 0
        limit = 10
    end
    user_id = nil
    begin
        request = client.prepare("SELECT id FROM users WHERE name = ? LIMIT 1")
        request.execute(params[:name]).each do |row|
            user_id = row["id"]
        end
        if user_id == nil
            return [
                404,
                { "Content-Type" => "application/json" },
                {error: "user not found"}.to_json
            ]
        else
            history = getUserHistory(user_id, client, limit)
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

####################################

# get '/tiltify/activate' do
#     if request.ip == "74.210.146.160"
#         response = $tiltify_api.get("/oauth/authorize?client_id=#{$client_id}&response_type=code&redirect_uri=https://server.venorrak.dev/tiltify/code") do |req|
#             req.headers["Authorization"] = "Bearer #{$access_token}"
#         end
#         return [
#             307,
#             { "Location" => response.headers["location"]},
#             ""
#         ]
#     end
# end 

# get '/tiltify/code' do
#     if request.ip == "74.210.146.160"
#         code = params[:code]
#         if code != nil
#             response = $tiltify_api.post("/oauth/token?client_id=#{$client_id}&client_secret=#{$client_secret}&grant_type=authorization_code&code=#{code}&redirect_uri=https://server.venorrak.dev/tiltify/code") do |req|
#                 req.headers["Authorization"] = "Bearer #{$access_token}"
#             end
#             begin
#                 rep = JSON.parse(response.body)
#                 $api_token = rep["access_token"]
#                 $refresh_token = rep["refresh_token"]
#                 p "got both tokens"
#             rescue
#                 p "continue"
#             end
#         else
#             rep = JSON.parse(response.body)
#             $api_token = rep["access_token"]
#             $refresh_token = rep["refresh_token"]
#             p "got both tokens"
#         end
#     end
# end

# get '/tiltify/rewards' do
#     if request.env["HTTP_AUTHORIZATION"] == "prodIsAwesome"
#         response = $tiltify_api.get("/api/public/campaigns/#{$campaign_id}/rewards") do |req|
#             req.headers["Authorization"] = "Bearer #{$api_token}"
#         end
#         return response.body
#     end
# end

# def refresh_token()
#     p $refresh_token
#     response = $tiltify_api.post("/oauth/token?client_id=#{$client_id}&client_secret=#{$client_secret}&grant_type=refresh_token&refresh_token=#{$refresh_token}") do |req|
#         req.headers["Authorization"] = "Bearer #{$access_token}"
#     end
#     rep = JSON.parse(response.body)
#     $api_token = rep["access_token"]
#     $refresh_token = rep["refresh_token"]
# end

# Thread.start do 
#     loop do
#         sleep(7100)
#         refresh_token()
#         p "refreshed token"
#     end
# end