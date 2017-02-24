require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require 'sinatra'
require 'sinatra/json'
require './models.rb'
require 'open-uri'
require 'time'

require 'twitter_oauth'

Time.zone = "Tokyo"
ActiveRecord::Base.default_timezone = :local

enable :sessions

before do
	key = ''
	secret = ''
	@twitter = TwitterOAuth::Client.new(
		:consumer_key => key,
		:consumer_secret => secret,
		:token => session[:access_token],
		:secret => session[:secret_token])
end

get '/' do
	@session = session
	@room_name = Room.order('id DESC').all
	erb :index
end

get '/request_token' do
	callback_url = "#{base_url}/access_token"
	request_token = @twitter.request_token(:oauth_callback => callback_url)
	session[:request_token] = request_token.token
	session[:request_token_secret] = request_token.secret
	redirect request_token.authorize_url
end

def base_url
	default_port = (request.scheme == "http") ? 80 : 443
	port = (request.port == default_port) ? "" : ":#{request.port.to_s}"
	"#{request.scheme}://#{request.host}#{port}"
end

get '/request_token' do
	callback_url = "#{base_url}/access_token"
	request_token = @twitter.request_token(:oauth_callback => callback_url)
	session[:request_token] = request_token.token
	session[:request_token_secret] = request_token.secret
	redirect request_token.authorize_url
end

get '/access_token' do
	begin
		@access_token = @twitter.authorize(session[:request_token], session[:request_token_secret],
																			 :oauth_verifier => params[:oauth_verifier])
	rescue OAuth::Unauthorized => @exception
		return erb :authorize_fail
	end

	session[:access_token] = @access_token.token
	session[:access_token_secret] = @access_token.secret
	session[:user_id] = @twitter.info['user_id']
	session[:screen_name] = @twitter.info['screen_name']
	session[:profile_image] = @twitter.info['profile_image_url_https']

	redirect '/'
end

get '/logout' do
	session.clear
	redirect '/'
end

post '/create_room' do
	room = Room.create({
		roomname: params[:room_name],
	})
	redirect '/'
end

get '/rooms/:room_id' do
	@session = session
	@room_name = Room.find_by(id: params[:room_id])
	@message = @room_name.messages
	erb :rooms
end

post '/send/message' do
	p params[:room_id]
	p params[:body]
	Message.create({
		body: params[:body],
		room_id: params[:room_id],
		username: params[:username], 
	})	
	#redirect "/rooms/#{params[:room_id]}"
	redirect back
end
