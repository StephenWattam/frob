

require 'frob/server'
require 'frob/store'

module Frob

  VERSION = '0.1.0'

  CONFIG_LOCATIONS = ['/etc/frob.yml',
                      '~/.frob.yml',
                      './frob.yml'
  ]

  WEB_ROOT = File.join(File.dirname(__FILE__), '../resources/webroot/')
end
