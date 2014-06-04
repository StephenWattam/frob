#!/usr/bin/ruby

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
    json_auth!

    # Read search term
    term = params[:term].to_s

    # Sanitise and offer as 'new' ID
    sanitised_input = $store.sanitise_id(term)
    return [].to_json if sanitised_input.length == 0

    # search using regexp
    results = $store.find(params[:term])
    results.delete(sanitised_input)
    results.sort!

    json_return([sanitised_input] + results)
  end

  # Rebuild internal index manually.
  post '/rebuild-index' do
    json_auth!

    # TODO: handle failure.
    $store.rebuild_index


    json_return('Index rebuilt')
  end

  # AJAX partial rendering thing
  get '/get/:id' do
    json_auth!

    id = $store.sanitise_id(params[:id])
    # json_return({id: id, bookmarked: false, is_template: false, card: nil}) unless $store.exist?(id)

    load_card(id)
    # TODO: if request.xhr render partial, else render with layout.

    json_return({:card => @card, :bookmarked => @bookmarked, :id => @id, :is_template => @is_template})
  end

  # Post to save
  post '/edit/:id' do
    json_auth!
    id = $store.sanitise_id(params[:id])

    # Parse hash
    hash = params[:fields] || {}
    return json_return('Invalid request', false) unless hash.is_a?(Hash)

    puts "HASH: #{hash}"

    # Write to store
    $store.put(id, hash);

    json_return(id)
  end

  # Delete a card permanently
  post '/delete/:id' do
    json_auth!

    id = $store.sanitise_id(params[:id])
    $store.delete(id)

    json_return(id)
  end

  # Return bookmark list
  get '/bookmarks' do 
    json_auth!

    json_return(($conf[:bookmarks] || []).sort)
  end

  # Add a bookmark
  post '/toggle-bookmark/:id' do
    json_auth!

    id = $store.sanitise_id(params[:id])
    $conf[:bookmarks] ||= []

    if $conf[:bookmarks].include?(id)
      $conf[:bookmarks].delete(id)
    else
      $conf[:bookmarks] << id
    end
   
    json_return(id)
  end
  
  # =================================================================
  # JSON return handler
  #

  # Return a standard-format JSON return
  def json_return(payload = nil, success = true)
    cache_control 'No-Cache'
    return {:success => !!success, :value => payload}.to_json
  end


  # =================================================================
  # Auth helper
  #

  def json_auth!
    json_return('Unauthed', false) unless session[:authed]
  end

  def auth!
    redirect '/login' unless session[:authed]
  end
  
  # =================================================================
  # JS ID helper
  #

  # Load card for rendering using the :card layout
  def load_card(id)
    @id          = $store.sanitise_id(id)
    @card        = $store[@id]
    @bookmarked  = ( $conf[:bookmarks] || [] ).include?(@id)
    @is_template = @id.to_s[-1] == CardStore::SEPARATOR
  end

end



# =================================================================
# Write config on shutdown
at_exit do

  puts 'Writing config file...'
  config_str = YAML.dump($conf)
  File.open(CONFIG_FILE, 'w') do |out|
    out.write(config_str)
  end
  puts 'Done'

end







# =================================================================
# Webrick HTTPS config.
#
require 'sinatra/base'
require 'webrick'
require 'webrick/https'
require 'openssl'

CERT_PATH = './ssl_certs'

webrick_options = {
        :Port               => 5746 ,
        :Logger             => WEBrick::Log::new($stderr, WEBrick::Log::INFO),
        :SSLEnable          => true,
        :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
        :SSLCertificate     => OpenSSL::X509::Certificate.new(  
                                 File.open(File.join(CERT_PATH, "frob.crt")).read),
        :SSLPrivateKey      => OpenSSL::PKey::RSA.new(
                                 File.open(File.join(CERT_PATH, "frob.key")).read),
        :SSLCertName        => [ [ "CN", WEBrick::Utils::getservername ] ]
}

Rack::Handler::WEBrick.run(Frob, webrick_options)
