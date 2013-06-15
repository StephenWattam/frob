Gem::Specification.new do |s|
  # About the gem
  s.name        = 'frob'
  s.version     = '0.0.1'
  s.date        = '2013-06-15'
  s.summary     = 'Secure online storage for login credentials and other small things'
  s.description = 'A secure interface to store information only occasionally needed'
  s.author      = 'Stephen Wattam'
  s.email       = 'stephenwattam@gmail.com'
  s.homepage    = 'http://stephenwattam.com/projects/frob'
  s.required_ruby_version =  ::Gem::Requirement.new(">= 2.0")
  s.license     = 'CC-BY-NC-SA 3.0' # Creative commons by-nc-sa 3

  # Files + Resources
  s.files         = Dir.glob("lib/**/*") + Dir.glob("resources/**/*")
  s.require_paths = ['lib']

  # Executables
  s.bindir      = 'bin'
  s.executables << 'frob'

  # Documentation
  s.has_rdoc         = false

  # Deps
  s.add_runtime_dependency 'markdown',          '~> 1.1'
  # s.add_runtime_dependency 'sqlite3',       '~> 1.3'
  # s.add_runtime_dependency 'mysql2',        '~> 0.3'
  # s.add_runtime_dependency 'simplerpc',     '~> 0.2'
  # s.add_runtime_dependency 'blat',     '~> 0.1'

end


