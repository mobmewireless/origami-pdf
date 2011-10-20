=begin

= File
	dictionary.rb

= Info
	This file is part of Origami, PDF manipulation framework for Ruby
	Copyright (C) 2010	Guillaume DelugrÈ <guillaume@security-labs.org>
	All right reserved.
	
  Origami is free software: you can redistribute it and/or modify
  it under the terms of the GNU Lesser General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Origami is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License
  along with Origami.  If not, see <http://www.gnu.org/licenses/>.

=end

module Origami

    class InvalidDictionaryObjectError < InvalidObjectError #:nodoc:
    end
  
    #
    # Class representing a Dictionary Object.
    # Dictionaries are containers associating a Name to an embedded Object.
    #
    class Dictionary < Hash
      include Origami::Object

      TOKENS = %w{ << >> } #:nodoc:      
      @@regexp_open = Regexp.new(WHITESPACES + Regexp.escape(TOKENS.first) + WHITESPACES)
      @@regexp_close = Regexp.new(WHITESPACES + Regexp.escape(TOKENS.last) + WHITESPACES)
      
      attr_reader :strings_cache, :names_cache, :xref_cache

      #
      # Creates a new Dictionary.
      # _hash_:: The hash representing the new Dictionary.
      #
      def initialize(hash = {})
        raise TypeError, "Expected type Hash, received #{hash.class}." unless hash.is_a?(Hash)
        super()
        
        @strings_cache = []
        @names_cache = []
        @xref_cache = {}

        hash.each_pair do |k,v|
          @names_cache.push(k.to_o)
          case val = v.to_o
            when String then @strings_cache.push(val)
            when Name then @names_cache.push(val)
            when Reference then
              (@xref_cache[val] ||= []).push(self)
            when Dictionary,Array then 
              @strings_cache.concat(val.strings_cache)
              @names_cache.concat(val.names_cache)
              @xref_cache.update(val.xref_cache) do |ref, cache1, cache2|
                cache1.concat(cache2)  
              end

              val.strings_cache.clear
              val.names_cache.clear
              val.xref_cache.clear
          end

          self[k.to_o] = val unless k.nil?
        end
      end
      
      def self.parse(stream) #:nodoc:
        
        offset = stream.pos

        if stream.skip(@@regexp_open).nil?
          raise InvalidDictionaryObjectError, "No token '#{TOKENS.first}' found"
        end
          
        pairs = {}
        while stream.skip(@@regexp_close).nil? do
          key = Name.parse(stream)
          
          type = Object.typeof(stream)
          if type.nil?
            raise InvalidDictionaryObjectError, "Invalid object for field #{key.to_s}"
          end
          value = type.parse(stream)
          
          pairs[key] = value
        end
       
        dict = 
          if Origami::OPTIONS[:enable_type_guessing]
            type = pairs[Name.new(:Type)]
            if type.is_a?(Name) and DICT_SPECIAL_TYPES.include?(type.value)
              DICT_SPECIAL_TYPES[type.value].new(pairs)
            else
              Dictionary.new(pairs)
            end

          else
            Dictionary.new(pairs)
          end

        dict.file_offset = offset

        dict
      end
      
      alias to_h to_hash
      
      def to_s(indent = 1)  #:nodoc:
        if indent > 0
          content = TOKENS.first + EOL
          self.each_pair do |key,value|
            content << "\t" * indent + key.to_s + " " + (value.is_a?(Dictionary) ? value.to_s(indent + 1) : value.to_s) + EOL
          end
          
          content << "\t" * (indent - 1) + TOKENS.last
        else
          content = TOKENS.first.dup
          self.each_pair do |key,value|
            content << "#{key.to_s} #{value.is_a?(Dictionary) ? value.to_s(0) : value.to_s}"
          end
          content << TOKENS.last
        end

        super(content)
      end
      
      def map!(&b)
        self.each_pair do |k,v|
          self[k] = b.call(v)
        end
      end

      def merge(dict)
        Dictionary.new(super(dict))
      end
      
      def []=(key,val)
        unless key.is_a?(Symbol) or key.is_a?(Name)
          fail "Expecting a Name for a Dictionary entry, found #{key.class} instead."
        end
        
        key = key.to_o
        if not val.nil?
          val = val.to_o
          super(key,val)
          
          key.parent = self
          val.parent = self unless val.is_indirect? or val.parent.equal?(self)

          val
        else
          delete(key)
        end
      end
      
      def [](key)
        super(key.to_o)
      end

      def has_key?(key)
        super(key.to_o)
      end

      def delete(key)
        super(key.to_o)
      end

      alias each each_value

      def real_type ; Dictionary end

      alias value to_h

      def method_missing(field, *args) #:nodoc:
        raise NoMethodError, "No method `#{field}' for #{self.class}" unless field.to_s[0,1] =~ /[A-Z]/

        if field.to_s[-1,1] == '='
          self[field.to_s[0..-2].to_sym] = args.first
        else
          obj = self[field]; 
          obj.is_a?(Reference) ? obj.solve : obj
        end
      end

    end #class
 
end # Origami
