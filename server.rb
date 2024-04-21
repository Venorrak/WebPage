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

set :port, 4567
set :bind, '0.0.0.0'

client = Mysql2::Client.new(:host => "localhost", :username => "bot", :password => "joel")
client.query("USE joelScan;")

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

get '/api/joels/users' do
    listUsers = Array.new
    way = params[:way]
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
    return [
        200,
        { "Content-Type" => "application/json" },
        listUsers.to_json
    ]
end

get '/api/joels/channels' do
    listChannels = Array.new
    way = params[:way]
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
    return [
        200,
        { "Content-Type" => "application/json" },
        listChannels.to_json
    ]
end