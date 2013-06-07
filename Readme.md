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

## Deploying example

Below are steps for getting the example running in its current state.

### Run locally

1. Install dependencies:

   ~~~~ .sh
   $ bundle install
   ~~~~

2. [Create an app on Facebook](https://developers.facebook.com/apps)
   and set the Website URL to `http://localhost:5000/`.

3. Copy the App ID and Secret from the Facebook app settings page into
   your `.env`:

   ~~~~ .sh
   echo FACEBOOK_APP_ID=12345 >> .env
   echo FACEBOOK_SECRET=abcde >> .env
   ~~~~

4. Launch the app with
   [Foreman](http://blog.daviddollar.org/2011/05/06/introducing-foreman.html):

   ~~~~ .sh
   foreman start
   ~~~~

### Deploy to Heroku via Facebook integration

The easiest way to deploy is to create an app on Facebook and click
Cloud Services -> Get Started, then choose Ruby from the dropdown.
You can then `git clone` the resulting app from Heroku.

### Deploy to Heroku directly

If you prefer to deploy yourself, push this code to a new Heroku app
on the Cedar stack, then copy the App ID and Secret into your config
vars:

~~~~ .sh
$ heroku create --stack cedar
$ git push heroku master
$ heroku config:add FACEBOOK_APP_ID=12345 FACEBOOK_SECRET=abcde
~~~~

Enter the URL for your Heroku app into the Website URL section of the
Facebook app settings page, then you can visit your app on the web.

## Get involved!

We are happy to receive bug reports, fixes, documentation enhancements,
and other improvements.

Please report bugs via the
[github issue tracker](http://github.com/memcachier/examples-sinatra/issues).

Master [git repository](http://github.com/memcachier/examples-sinatra):

* `git clone git://github.com/memcachier/examples-sinatra.git`

## Licensing

This library is BSD-licensed.

