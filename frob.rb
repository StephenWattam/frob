#!/usr/bin/rbx


# Bundle
require 'rubygems'
require 'bundler/setup'

# Sinatra
require 'sinatra/base'
require 'sinatra/flash'
require 'rack/ssl'


class Frob < Sinatra::Base

  # Session handling
  use Rack::Session::Cookie, 
    :expire_after => 2592000, 
    :secret => 'sTGfereFERha4he8akuresgh8kr3hy8ioz'

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


  # Use flash
  register Sinatra::Flash



  # TEST
  get '/' do
    "STUFF"
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
