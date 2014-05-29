#!/usr/bin/rbx

CONFIG_FILE = './frob.yml'



# Bundle
require 'rubygems'
require 'bundler/setup'

# Sinatra
require 'sinatra/base'
require 'sinatra/flash'
require 'rack/ssl'
require 'less'

# Helpers
require_relative './lib/helpers/formatting'
require_relative './lib/helpers/sanitise'

# Config
require 'yaml'
require 'digest/sha1' # pw hashing

# Storage layer
require_relative './lib/card_store'

# AJAX API
require 'json'

# =================================================================
# Config
#
$conf  = YAML.load(File.read(CONFIG_FILE))     or fail "Could not load main config"
$store = CardStore.new($conf[:store_dir])











class Frob < Sinatra::Base

  # Session handling
  use Rack::Session::Cookie, 
    :expire_after => [$conf[:session_timeout].to_i, 60 * 5].min, 
    :secret       => 'sTGfereFERha4he8akuresgh8kr3hy8ioz'

  # SSL
  use Rack::SSL

  # configure environments
  configure do
    # Options
    enable  :sessions, :logging, :run
    set     :port, 5746
  end
  configure :development do
    enable :dump_errors, :show_exceptions
  end
  configure :production do
    disable :dump_errors
  end

  # Allow LessCSS @import to work
  Less.paths << settings.views

  # Use flash
  register Sinatra::Flash

  # Custom helpers
  helpers Formatting
  helpers Sanitise

  # =================================================================
  # Use LESS for CSS
  get '/css/:style.css' do
    less "/css/#{params[:style]}".to_sym
  end

  
  # =================================================================
  # TEST
  get '/' do
    auth!

    erb :index
  end

  # Prompt for login
  get '/login' do
    erb :login, :layout => nil
  end

  # Accept login
  post '/login' do
    # Hash in same way as generation tool 
    hash = Digest::SHA1.hexdigest("#{$conf[:pass_salt]}#{params[:password].encode('utf-8')}")
 
    # Check against config.
    if hash == $conf[:pass_hash]
      session[:authed] = true
    else
      flash[:fail] = 'Wrong password.'
      redirect '/login'
    end

    redirect '/'
  end

  # Log out (get)
  # GET is non-REST for this really
  get '/logout' do
    auth!
    session[:authed] = false

    flash[:success] = 'Logged out.'
    redirect '/'
  end


  # =================================================================
  # AJAX Interaction
  #
  
  # JSON search API
  get '/search' do
    auth!

    # Read search term
    term = params[:term].to_s

    # Sanitise and offer as 'new' ID
    sanitised_input = $store.sanitise_id(term)
    return [].to_json if sanitised_input.length == 0

    # search using regexp
    results = $store.find(params[:term])

    return ([sanitised_input] + results).to_json
  end

  # Rebuild internal index manually.
  get '/rebuild-index' do
    auth!

    $store.rebuild_index

    redirect '/'
  end

  # AJAX partial rendering thing
  get '/get/:id' do
    auth!

    @id = $store.sanitise_id(params[:id])
    @js_id = @id.gsub('.', '_') # JS safe ID
    @card = $store[@id]
    @bookmarked = ( session[:bookmarks] || [] ).include?(@id)

    # TODO: if request.xhr render partial, else render with layout.

    erb :card, :layout => nil
  end

  # Return bookmark list
  get '/bookmarks' do 
    auth!
    erb :bookmark_list, :layout => nil
  end

  # Add a bookmark
  get '/toggle-bookmark/:id' do
    auth!

    id = $store.sanitise_id(params[:id])
    session[:bookmarks] ||= []

    if session[:bookmarks].include?(id)
      session[:bookmarks].delete(id)
    else
      session[:bookmarks] << id
    end
    
    return id
  end

  # =================================================================
  # Auth helper
  #

  def auth!
    redirect '/login' unless session[:authed]
  end

end












require 'sinatra/base'
require 'webrick'
require 'webrick/https'
require 'openssl'

CERT_PATH = './ssl_certs'

webrick_options = {
        :Port               => 5746 ,
        :Logger             => WEBrick::Log::new($stderr, WEBrick::Log::DEBUG),
        :SSLEnable          => true,
        :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
        :SSLCertificate     => OpenSSL::X509::Certificate.new(  
                                 File.open(File.join(CERT_PATH, "frob.crt")).read),
        :SSLPrivateKey      => OpenSSL::PKey::RSA.new(
                                 File.open(File.join(CERT_PATH, "frob.key")).read),
        :SSLCertName        => [ [ "CN", WEBrick::Utils::getservername ] ]
}

Rack::Handler::WEBrick.run(Frob, webrick_options)
