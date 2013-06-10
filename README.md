# MemCachier Ruby & Facebook Example

This is an example Ruby app that uses
[MemCachier](http://www.memcachier.com) to cache data from the
Facebook Graph API. This example is written using the Sinatra web
framework. It's currently running at
[memcachier-examples-sinatra.herokuapp.com](https://memcachier-examples-sinatra.herokuapp.com/)

## Setup MemCachier

Setting up MemCachier to work in Ruby is very easy. You need to make
changes to Gemfile, and any app code that you want cached. These
changes are covered in detail below.

### Gemfile

MemCachier has been tested with the [dalli memcache
client](https://github.com/mperham/dalli). Add the following Gem to
your Gemfile:

~~~~ .ruby
gem 'memcachier'
gem 'dalli'
~~~~

Then run `bundle install` as usual.

Note that the `memcachier` gem simply sets the appropriate environment
variables for Dalli. You can also do this manually in your
production.rb file if you prefer:

~~~~ .ruby
ENV["MEMCACHE_SERVERS"] = ENV["MEMCACHIER_SERVERS"]
ENV["MEMCACHE_USERNAME"] = ENV["MEMCACHIER_USERNAME"]
ENV["MEMCACHE_PASSWORD"] = ENV["MEMCACHIER_PASSWORD"]
~~~~

Alternatively, you can pass these options to config.cache_store (also
in production.rb):

~~~~ .ruby
config.cache_store = :dalli_store, ENV["MEMCACHIER_SERVERS"],
                    {:username => ENV["MEMCACHIER_USERNAME"],
                     :password => ENV["MEMCACHIER_PASSWORD"]}
~~~~

### Sinatra setup

Ensure that the following configuration option is set in your Sinatra
web app at the start.

~~~~ .ruby
set :cache, Dalli::Client.new
~~~~

## Using MemCachier

We can use MemCachier to cache the list of friends a user has.
Normally we have to query Facebook for this information which is slow.

    ~~~~ .ruby
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
    ~~~~

## Deploying example

Below are steps for getting the example running in its current state.
If you run into any problems you can follow the more extensive [Heroku
guide](https://devcenter.heroku.com/articles/facebook) for running
Facebook web apps locally and on Heroku.

### Run locally

1. Install dependencies:

   ~~~~ .sh
   $ bundle install
   ~~~~

2. [Create an app on Facebook](https://developers.facebook.com/apps).
   Select 'Website' for how the app will interact with Facebook and
   set the 'Site URL' to be 'http://127.0.0.1:5000/'.

3. Copy the App ID and Secret from the Facebook app settings page into
   your `.env`:

   ~~~~ .sh
   echo FACEBOOK_APP_ID=12345 >> .env
   echo FACEBOOK_SECRET=abcde >> .env
   ~~~~

4. Launch the app with Foreman.

   ~~~~ .sh
   foreman start
   ~~~~

### Deploy to Heroku via Facebook integration

The easiest way to deploy a completely new app to Facebook using
Heroku is to follow the [Heroku
guide](https://devcenter.heroku.com/articles/facebook).

To deploy this app to Facebook:

1. Create a new Facebook application (different from the one used for
   local development). On the 'Create New App' dialog box at the
   start, select the option for 'Web Hosting' with Heorku. For the
   application type, select Ruby.

2. This will create a new Heroku application that is setup with
   Facebook correctly. Clone this new application from Heroku to you
   local machine.

3. Replace the existing template application that Heroku provides with
   the code from this repository.

4. Commit the change and deploy to Heroku.

## Get involved!

We are happy to receive bug reports, fixes, documentation enhancements,
and other improvements.

Please report bugs via the
[github issue tracker](http://github.com/memcachier/examples-sinatra/issues).

Master [git repository](http://github.com/memcachier/examples-sinatra):

* `git clone git://github.com/memcachier/examples-sinatra.git`

## Licensing

This library is BSD-licensed.

