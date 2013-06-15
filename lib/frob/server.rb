

module Frob

  # Controls the frob web front-end
  class Server

    # HTTPS capability
    require 'webrick'
    require 'webrick/https'

    def initialize(store, auth_list, security_credentials, iface = 'localhost', port = 8080)
      @store      = store
      @interface  = iface
      @port       = port
      
      if security_credentials.is_a?(Hash)
        require 'openssl'
        @cert = OpenSSL::X509::Certificate.new(File.read(security_credentials[:certificate]))
        @pkey = OpenSSL::PKey::RSA.new(File.read(security_credentials[:privkey]))
      end


      # ----------------------------------------------------------------------------
      # Construct auth system
      #
      @auth_list = auth_list
      @auth = Proc.new do |req, res|
        WEBrick::HTTPAuth.basic_auth(req, res, '') do |user, password|
          puts "AUTH CHALLENGE for user #{user}."
          @auth_list && @auth_list[user.to_s] == Digest::SHA512.hexdigest(password.to_s)
        end
      end

    end

    def start
      # Process options from before
      opts = {Port: @port, Hostname: @interface, :SSLEnable => true,
              SSLCertName: WEBrick::Utils::getservername}

      if @cert and @pkey then
        puts "Using certificate and private key for SSL"
        opts[:SSLCertificate]   = @cert
        opts[:SSLPrivateKey]    = @pkey
      else
        puts "Using self-signed certificate for SSL"
      end

      # Create the server
      server = WEBrick::HTTPServer.new(opts)


      # File listing and original serving of index.html
      server.mount('/', WEBrick::HTTPServlet::FileHandler,
                   Frob::WEB_ROOT, 
                   # :FancyIndexing => true,
                   :HandlerCallback => @auth
                  )
      # Web app 
      server.mount('/frob/', FrobServer,
                   FrobApplication.new(@store),
                   { :HandlerCallback => @auth }
                  )

      # Shutdown on signal
      trap 'INT' do server.shutdown end

      # Serve
      server.start
    end
  end

  # --------------------------------------------------------------------------

  # Handles requests from the web side
  class FrobServer < WEBrick::HTTPServlet::AbstractServlet

    require 'json'

    # Construct a new ActionServer with a given set of actions,
    # and some options for callbacks( such as http auth ).
    def initialize(server, app, opts = {})
      super(server)
      @app = app
      @handler = opts[:HandlerCallback]
    end

    # Handle a get request
    def do_GET request, response
      @handler.call(request, response) if @handler
      body = make_request(request)

      response.status = 200
      response['Content-Type'] = 'text/json' 
      response.body = JSON.dump(body)
    end

    # Handle a post request
    def do_POST request, response
      @handler.call(request, response) if @handler
      body = make_request(request)

      response.status = 200
      response['Content-Type'] = 'text/json' 
      response.body = JSON.dump(body)
    end

    private

    # Handle a request to the server.
    # Called by get and post.
    def make_request request
      puts "\n\n-f-r-o-b-"
      puts "==> Request, action='#{request.path}', params = #{request.query}..."
  
      action = request.path.to_s.split("/")[-1]

      if action && @app.valid?(action) then
        params = JSON.parse(request.query['params'] || '[]')
        puts "PARAMS: #{params}"
        response = @app.send(action.to_sym, *params)

        return {'success' => response}
      end

      return {'error' => "Unrecognised action: #{action}" }
    rescue Exception => e
      $stderr.puts "*** [E]: #{e}\n#{e.backtrace.join("\n")}"
      return {'error' => "Exception: #{e}\n#{e.backtrace.join("\n")}"}
    end
  end

  
  # --------------------------------------------------------------------------

  class FrobApplication

    require 'markdown'

    # List valid actions for internal use
    VALID_ACTIONS = %w{notes_by_category get_note}

    # 
    def initialize(store)
      @store = store
    end

    # Is the action valid at this time?
    def valid?(action)
      self.respond_to?(action.to_sym) && VALID_ACTIONS.include?(action)
    end

    # Return a big list of notes in format:
    #  category => [ {id => name} ]
    def notes_by_category()
      @store.category_membership.map do |cat, ids|
        ids.map { |id| {id: id, title: @store.name_from_id(id)} }
      end
    end

    def get_note(id)
      id = id.to_i

      raise "No note exists with id #{id}" unless note = @store[id]

      return {:id => id, :name => note.name, :text => note.text, :categories => note.categories,
              :html_text => Markdown.new(note.text).to_html }
    end

  end

end
