# MemCachier Facebook & Sinatra Example
# =====================================
#
# We use Memcache to cache a users list of friends for fast searches (avoid
# slow query to FB). Two improvements could be made to this current code (if
# you are using this for a production app):
# 1) We reconnect to FB each page load -- should instead pool connections.
# 2) We rebuild the hashmap of our friends cities each time, could instead
# cache that in memcache.
#
require "sinatra"
require 'koala'
require 'dalli'
require 'memcachier'

enable :sessions
set :raise_errors, false
set :show_exceptions, false

# ============================================================================
# MemCachier Setup
# ================
set :cache, Dalli::Client.new

## May need to pass in the MEMCACHIER_SERVERS, MEMCACHIER_USERNAME,
## MEMCACHIER_PASSWORD if _not_ using the memcachier gem, as above depends on
## the environment varialbes being set and passed in by the gem. Alternative is:
# set :cache, Dalli::Client.new(ENV["MEMCACHIER_SERVERS"],
#                   {:username => ENV["MEMCACHIER_USERNAME"],
#                    :password => ENV["MEMCACHIER_PASSWORD"]}
# ============================================================================


# Define facebook permissions needed.
# See https://developers.facebook.com/docs/reference/api/permissions/
# for a full list of permissions
FACEBOOK_SCOPE = 'user_likes,user_photos,user_location,friends_location'

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
  def host
    request.env['HTTP_HOST']
  end

  def scheme
    request.scheme
  end

  def url_no_scheme(path = '')
    "//#{host}#{path}"
  end

  def url(path = '')
    "#{scheme}://#{host}#{path}"
  end

  def authenticator
    @authenticator ||= Koala::Facebook::OAuth.new(ENV["FACEBOOK_APP_ID"], ENV["FACEBOOK_SECRET"], url("/auth/facebook/callback"))
  end

  # allow for javascript authentication
  def access_token_from_cookie
    authenticator.get_user_info_from_cookies(request.cookies)['access_token']
  rescue => err
    warn err.message
  end

  def access_token
    session[:access_token] || access_token_from_cookie
  end

  # MemCachier
  # ==========
  # Retrieve friends list from MemCachier if possible.
  def get_friends
    # cache using session id as the key. May want to use a more permanent key
    # that is meaningful across sessions.
    @friends ||= settings.cache.fetch("#{session[:at]}:friends") do
      # CACHE MISS -- so hit fb graph api and then store result in cache.
      @graph = Koala::Facebook::API.new(access_token)
      friends = @graph.fql_query("SELECT uid, name, current_location FROM user WHERE uid in (SELECT uid2 FROM friend WHERE uid1 = me())")
      settings.cache.set("#{session[:at]}:friends", friends, 600) # cache for 10 minutes
      friends
    end
  end

  # MemCachier
  # ==========
  # Retrieve my own facebook app info.
  def get_app
    @app ||= settings.cache.fetch("myapp") do
      # CACHE MISS -- so hit fb graph api and then store result in cache.
      @app = @graph.get_object(ENV["FACEBOOK_APP_ID"])
      settings.cache.set("myapp", @app, 60 * 60) # cache for 1 hour
    end
  end

end

# the facebook session expired! reset ours and restart the process
error(Koala::Facebook::APIError) do
  session[:access_token] = nil
  redirect "/auth/facebook"
end

get "/" do
  # Get base API Connection
  @graph = Koala::Facebook::API.new(access_token)
  # TODO: ^ Would want to keep a permanent connection to FB, not open a new one
  # each page load.

  # Get public details of current application
  get_app

  if access_token
    @user = @graph.get_object("me")
  end
  erb :index
end

# used by Canvas apps - redirect the POST to be a regular GET
post "/" do
  redirect "/"
end

# Build a list of cities friends live in for autocompletion (JSON API).
get "/search" do
  content_type :json
  query = params[:term].downcase

  @graph  = Koala::Facebook::API.new(access_token)

  if access_token
    # build list of cities friends live in for type-completion.
    cities = get_friends.map do |friend|
      friend["current_location"] and friend["current_location"]["city"]
    end
    cities.uniq!
    
    result = cities.select do |city|
      city and city.downcase.index(query)
    end
  else
    # not authorized...
    result = "must be logged in to access"  
  end

  result.to_json
end

# Query a city for a list of friends that live there (JSON API)
get "/friends_in" do
  content_type :json
  query = params[:city].downcase

  @graph  = Koala::Facebook::API.new(access_token)

  if access_token
    # finds friends who live in the specified city.
    result = get_friends.select do |friend|
      if friend["current_location"]
        friend["current_location"]["city"].downcase == query
      else
        nil
      end
    end
  else
    # not authorized...
    result = "must be logged in to access"  
  end

  result.to_json
end

# ============================================================================
# Facebook oauth handling

get "/close" do
  "<body onload='window.close();'/>"
end

get "/preview/logged_out" do
  session[:access_token] = nil
  request.cookies.keys.each { |key, value| response.set_cookie(key, '') }
  redirect '/'
end


get "/auth/facebook" do
  session[:access_token] = nil
  redirect authenticator.url_for_oauth_code(:permissions => FACEBOOK_SCOPE)
end

get '/auth/facebook/callback' do
  session[:access_token] = authenticator.get_access_token(params[:code])
  redirect '/'
end

