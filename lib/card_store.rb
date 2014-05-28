
require 'yaml'

# Case-ignorant store of hierarchical
# cards
class CardStore

  SEPARATOR           = '.'
  EXTENSION           = '.yml'
  FILES_DIR_EXTENSION = '_files'

  def initialize(data_dir)
    # Check dir and save in object
    fail "Data directory does not exist (#{data_dir})" unless File.exist?(data_dir) && 
                                                              File.directory?(data_dir)
    @data_dir = data_dir

    # Keep an index cache
    @index = {}
    rebuild_index
  end


  # ------------------------------------------------------
  # Utility and storage state
  #

  # Rebuild the cache used for
  # title searches
  def rebuild_index
    files = Dir.glob(File.join(@data_dir, "*.#{EXTENSION}"))
    files.delete_if { |f| File.directory?(f) || !File.readable(f) }
    files.each do |f|
      id         = sanitise_id(File.basename(f, ".#{EXTENSION}"))
      @index[id] = list_files(id)
    end
  end

  # Return a template ID 
  # for any given id
  def get_template_id(id)
    id = sanitise_id(id)
    parts = chunk(id)
    template_id = "#{parts[0..-2].join(SEPARATOR)}#{SEPARATOR}"
    return template_id
  end

  # Return the template content for any given ID
  def get_template(id)
    id = sanitise_id(id)
    return load_yaml(get_template_id(id))
  end

  # Does an ID exist (raw, not a prefix or rx search)
  def exists?(id)
    id = sanitise_id(id)
    @index.include?(id)
  end

  # ------------------------------------------------------
  # CRUD Operations
  #

  # Return a card if it exists, or a blank one if not
  def get(id)
    id = sanitise_id(id)
    return load_yaml(id)
  end
  alias_method :'[]', :get

  # Delete a card
  def delete(id)
    id = sanitise_id(id)

    # Delete from disk
    FileUtils.rm(card_filename(id))
    dir = card_file_dir(id)
    FileUtils.rm_r(dir) if File.exist?(dir) && File.directory?(dir)

    # Delete from index
    @index.delete(id)
  end

  # Delete a file from a card.
  def delete_file(id, filename)
    id = sanitise_id(id)
    return false unless @index[id].include?(filename)
    filename = card_file_filename(id, filename)
    return true unless File.exist?(filename)
    FileUtils.rm(filename)
  end

  # Update
  def update(id, value = {})
    id = sanitise_id(id)
    fail 'Value is not a hash' unless value.is_a?(Hash)
    write_yaml(id, value)
  end
  alias_method :'[]=', :update

  # Update/write/set a file.
  # Yields an IO object to write to
  def update_file(id, filename, mode = 'wb')
    id = sanitise_id(id)
    filename = card_file_filename(id, filename)
    File.open(filename, mode) do |io_out|
      yield(io_out)
    end
  end
  
  # ------------------------------------------------------
  # Search API
  #

  # Find by prefix.  If a block is given
  # each is yielded, else it's returned as a list
  def find_prefix(id_prefix)
    found = []
    @index.keys.each do |k|
      if k =~ /^#{id_prefix}/
        found << k 
        yield(k, get(k)) if block_given?
      end
    end
    return found
  end

  # Find by regexp.  If block given then each is
  # yielded
  def find(id_rx)
    found = []
    id_rx = Regexp.new(id_rx) unless id_rx.is_a?(Regexp)
    @index.keys.each do |k|
      if k =~ id_rx
        found << k
        yield(k, get(k)) if block_given?
      end
    end
    return found
  end
  
  # Iterate over the lot.  Yields the item itself
  def each
    @index.keys.each do |k|
      yield(get(k))
    end
  end

private

  # Ensure an ID is valid, and return a valid form
  # if so
  def sanitise_id(id)
    id.to_s.downcase.gsub(/[^\w.]/, '').gsub(/\.{1,}/, '.')
  end
  
  # Load from YAMl file on disk
  def load_yaml(id)
    return {} unless @index[id]
    hash   = YAML.load(File.read(card_filename(id))) or fail "Could not load id #{id}"
    hash ||= {}
    hash[:_files] = list_files(id) if @index[id].length > 0
    return hash
  end

  def write_yaml(id, hash)
    filename = card_filename(id)
    File.open(filename, 'w') do |io_out|
      YAML.dump(hash, io_out)
    end
  end

  # List filenames for this ID
  def list_files(id)
    dir = card_file_dir(id)
    return [] unless File.exist?(dir) && File.directory?(dir)
    return Dir.glob(File.join(dir, '*')).map { |f| File.basename(f) }
  end

  # Return a filename from an ID
  def card_filename(id)
    File.join(@data_dir, "#{id}.#{EXTENSION}")
  end

  # Return the name of the directory
  # where attached files are stored
  def card_file_dir(id)
    File.join(@data_dir, "#{id}#{FILES_DIR_EXTENSION}")
  end

  # Card file filename
  def card_file_filename(id, filename)
    File.join(card_file_dir, filename)
  end

  # Split an ID into chunks
  def chunk(id)
    id.split('.')
  end

end
