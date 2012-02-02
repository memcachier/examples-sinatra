require "sinatra"
require "mogli"

enable :sessions
set :raise_errors, false
set :show_exceptions, false
set :cache, Dalli::Client.new

unless ENV["FACEBOOK_APP_ID"] && ENV["FACEBOOK_SECRET"]
  abort("missing env vars: please set FACEBOOK_APP_ID and FACEBOOK_SECRET with your app credentials")
end

before do
  # HTTPS redirect
  if settings.environment == :production && request.scheme != 'https'
    redirect "https://#{request.env['HTTP_HOST']}"
  end
end

helpers do
  def url(path)
    base = "#{request.scheme}://#{request.env['HTTP_HOST']}"
    base + path
  end

  def authenticator
    @authenticator ||= Mogli::Authenticator.new(ENV["FACEBOOK_APP_ID"], ENV["FACEBOOK_SECRET"], url("/auth/facebook/callback"))
  end
  
  def client
    @client ||= Mogli::Client.new(session[:at])
  end
  
  def friends
    @friends ||= settings.cache.fetch("#{session[:at]}:friends") do
      friends = client.fql_query("SELECT uid, name, current_location FROM user WHERE uid in (SELECT uid2 FROM friend WHERE uid1 = me())")
      settings.cache.set("#{session[:at]}:friends", friends, 60)
      friends
    end
  end

end

# the facebook session expired! reset ours and restart the process
error(Mogli::Client::HTTPException) do
  session[:at] = nil
  redirect "/auth/facebook"
end

get "/" do
  redirect "/auth/facebook" unless session[:at]
  @client = Mogli::Client.new(session[:at])

  @user = settings.cache.fetch("#{session[:at]}:me") do
    user = Mogli::User.find("me", @client)
    settings.cache.set("#{session[:at]}:me", user, 60)
    user
  end
  
  friends

  erb :index
end

get "/search" do
  
  content_type :json
  query = params[:term].downcase
  result = friends.select do |friend|
    if friend["current_location"]
      friend["name"].downcase.index(query)
    else
      nil
    end
  end
  result = result.map do |friend|
      {:label => friend["name"], :value => friend["current_location"]["name"] }
  end
  result.to_json
end

get "/auth/facebook" do
  session[:at]=nil
  redirect authenticator.authorize_url(:scope => "user_location,friends_location", :display => 'page')
end

get '/auth/facebook/callback' do
  client = Mogli::Client.create_from_code_and_authenticator(params[:code], authenticator)
  session[:at] = client.access_token
  puts session[:at]
  redirect '/'
end
