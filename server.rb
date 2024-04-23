require "bundler/inline"
require "openssl"

gemfile do
    source "http://rubygems.org"

    gem "sinatra-contrib"
    gem "rackup"
    gem "webrick"
    gem "mysql2"
end

require "json"
require 'sinatra'
require "mysql2"
require_relative "auth.rb"

set :port, 4567
set :bind, '0.0.0.0'

client = Mysql2::Client.new(:host => "localhost", :username => "bot", :password => "joel")
client.query("USE joelScan;")

#-----------------------------------------------------------------------#
#------------------------------FUNCTIONS--------------------------------#
#-----------------------------------------------------------------------#

def guard!
    auth_required = [
      401,
      {
        "WWW-Authenticate" => "Basic"
      },
      "Invalid credentials".to_json
    ]
  
    # HALT interrompt IMMEDIATEMENT la requête et retourne le resultat
    halt auth_required unless authorized?
end
  
def authorized?
    auth ||=  Rack::Auth::Basic::Request.new(request.env) 
    # request.env est disponible car on est dans le block HELPERS
    return unless auth.provided? && auth.basic? && auth.credentials
  
    username, password = auth.credentials
    $loginInfo = authenticate(username, password)
    p $loginInfo
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
    return send_file "html/userStats.html"
end

get '/joels/channels' do
    return send_file "html/channelStats.html"
end

get '/manage' do
    guard!
    return send_file "html/manage.html"
end

#-----------------------------------------------------------------------#
#------------------------------ACTIONS ROUTES---------------------------#
#-----------------------------------------------------------------------#



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
    end
end

get '/api/joels/users/:name' do
    user = client.query("SELECT users.name, users.creationDate AS 'date', joels.count FROM users join joels on joels.user_id = users.id WHERE users.name = '#{params[:name]}'").first
    if user == nil
        return [
            404,
            { "Content-Type" => "application/json" },
            {error: "user not found"}.to_json
        ]
    else
        return [
            200,
            { "Content-Type" => "application/json" },
            user.to_json
        ]
    end
end

get '/api/joels/channels/:name' do
    channel = client.query("SELECT channels.name, channels.creationDate AS 'date', channelJoels.count FROM channels join channelJoels on channelJoels.channel_id = channels.id WHERE channels.name = '#{params[:name]}'").first
    if channel == nil
        return [
            404,
            { "Content-Type" => "application/json" },
            {error: "channel not found"}.to_json
        ]
    else
        return [
            200,
            { "Content-Type" => "application/json" },
            channel.to_json
        ]
    end
end

#-----------------------------------------------------------------------#
#--------------------------------OTHER----------------------------------#
#-----------------------------------------------------------------------#
