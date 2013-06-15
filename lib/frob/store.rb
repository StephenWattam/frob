
module Frob

  class Record

    attr_reader :name, :text, :categories

    def initialize(name, text, categories = [])
      @name = name
      @text = text
      @categories = categories
    end
  end

  # TODO: PStore is not necessarily safe for long-term storage
  # of sensitive things.
  #
  # Add an export tool to export to YAML or JSON, then people won't 
  # be without their passwords if the ruby marshal format
  # changes
  #
  # It might be worth making a backup every time the store is loaded too
  # TODO: thread safety.
  class Store

    require 'pstore'
    require 'set'

    def initialize(file)
      @file     = file

      # Set up store
      @pstore   = PStore.new(file)
      @pstore.ultra_safe = true

      # Load search indices
      @indices  = ps { |s| s[:__indices] }

      if !@indices
        @indices = {}
        @indices[:names]      = {}
        @indices[:categories] = {}
        @indices[:highest_id] = 0 # okay, so not strictly an index...
      end
    end

    # List all categories
    def categories
      @indices[:categories].keys
    end

    # Return a {category => [id]} list
    def category_membership
      @indices[:categories]
    end

    # List all names as a hash {id => name}.
    def names
      @indices[:names]
    end

    def name_from_id(id)
      @indices[:names][id]
    end

    # List IDs with a given category
    def list_members_of_category(cat)
      @indices[:categories][cat]
    end

    # Return a list of names and IDs matching a given search
    def search_name(rx)
      hits = []

      @indices[:names].each { |name, id|
        hits << [name, id] if name =~ rx
      }

      return hits
    end

    # -------------------------------------------------------------------------------------------
    # Easy api

    # Add a record and return the new ID
    def <<(record)
      write(record)
    end

    # Overwrite or write a new id, or delete if setting [id] = nil
    def []=(id, record)
      write(record, true, id)
    end

    # Read a record
    def [](id)
      read(id)
    end


    # --------------------------------------------------------------------------------------------
    # Low-level ops
  
    # Read a given record
    def read(id)
      ps { |p| p[id] }
    end

    # Write a record to disk with a given ID
    def write(record, overwrite = false, id = nil)

      # Remove if setting to nil
      if id && !record
        delete(id)
      end

      # Do nothing if writing nil to the end
      return nil if !id && !record

      ps(false) do |p|

        # Generate an ID if none given
        id = (@indices[:highest_id] += 1) unless id
        
        # Read old record if one exists
        old_record = p[id]

        # Remove categories that don't exist in new one
        new_categories = record.categories
        if old_record

          raise "Cannot overwrite old record with id #{id}" unless overwrite

          dropped_categories = old_record.categories - record.categories
          new_categories     = record.categories - old_record.categories

          # Remove ourselves from the category index
          if dropped_categories.length > 0
            dropped_categories.each{|dc| @indices[:categories][dc].delete(id) if @indices[:categories][dc] }
          end
        end

        # Add ourselves to any categories we are newly in
        new_categories.each { |nc| 
          @indices[:categories][nc] = Set.new unless @indices[:categories][nc]
          @indices[:categories][nc] << id }

        # Update names index
        @indices[:names][id] = record.name

        # Then replace stuff
        p[id] = record

      end

      return id
    end

    # Delete a record
    def delete(id)
      ps(false) do |p|
        p[id] = nil
      end
    end

    # Close and write indices.
    def close
      ps(false) do |p|
        p[:__indices] = @indices
      end
    end

  private

    # Shorter syntax for pstore, with default
    # being read-only
    def ps(ro = true, &block)
      @pstore.transaction(ro) do 
        yield(@pstore)
      end
    end
  end

end
