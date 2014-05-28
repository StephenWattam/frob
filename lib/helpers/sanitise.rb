

require 'rack'

module Sanitise 

  # HTML escape
  def h(text)
    Rack::Utils.escape_html(text.to_s)
  end

  # HTML unescape
  def _h(text)
    Rack::Utils.unescape_html(text.to_s)
  end
  
  # URI escape
  def u(text)
    Rack::Utils.escape(text.to_s)
  end

  # URI unescape
  def _u(text)
    Rack::Utils.unescape(text.to_s)
  end

end
