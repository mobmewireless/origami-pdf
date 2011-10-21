=begin

= File
	filters.rb

= Info
	This file is part of Origami, PDF manipulation framework for Ruby
	Copyright (C) 2010	Guillaume Delugré <guillaume@security-labs.org>
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

  #
  # Filters are algorithms used to encode data into a PDF Stream.
  #
  module Filter

    class InvalidFilterDataError < Exception # :nodoc:
      attr_reader :decoded_data

      def initialize(message, decoded_data = nil)
        super(message)

        @decoded_data = decoded_data
      end
    end

    module Utils
      
      class BitWriterError < Exception #:nodoc:
      end
      
      #
      # Class used to forge a String from a stream of bits.
      # Internally used by some filters.
      #
      class BitWriter
        def initialize
          @data = ''
          @last_byte = nil
          @ptr_bit = 0
        end

        #
        # Writes _data_ represented as Fixnum to a _length_ number of bits.
        #
        def write(data, length)
          return BitWriterError, "Invalid data length" unless length > 0 and (1 << length) > data

          # optimization for aligned byte writing
          if length == 8 and @last_byte.nil? and @ptr_bit == 0
            @data << data.chr
            return self
          end

          while length > 0
            if length >= 8 - @ptr_bit
              length -= 8 - @ptr_bit
              @last_byte = 0 unless @last_byte
              @last_byte |= (data >> length) & ((1 << (8 - @ptr_bit)) - 1)

              data &= (1 << length) - 1
              @data << @last_byte.chr
              @last_byte = nil
              @ptr_bit = 0
            else
              @last_byte = 0 unless @last_byte
              @last_byte |= (data & ((1 << length) - 1)) << (8 - @ptr_bit - length)
              @ptr_bit += length
              
              if @ptr_bit == 8
                @data << @last_byte.chr
                @last_byte = nil
                @ptr_bit = 0
              end
              
              length = 0
            end
          end

          self
        end

        #
        # Returns the data size in bits.
        #
        def size
          (@data.size << 3) + @ptr_bit
        end

        #
        # Finalizes the stream.
        #
        def final
          @data << @last_byte.chr if @last_byte
          @last_byte = nil
          @p = 0

          self
        end

        #
        # Outputs the stream as a String.
        #
        def to_s
          @data.dup
        end
      end

      class BitReaderError < Exception #:nodoc:
      end

      #
      # Class used to read a String as a stream of bits.
      # Internally used by some filters.
      #
      class BitReader
        def initialize(data)
          @data = data
          reset
        end

        #
        # Resets the read pointer.
        #
        def reset
          @ptr_byte, @ptr_bit = 0, 0
          self
        end

        #
        # Returns true if end of data has been reached.
        #
        def eod?
          @ptr_byte >= @data.size
        end

        #
        # Returns the read pointer position in bits.
        #
        def pos
          (@ptr_byte << 3) + @ptr_bit
        end

        #
        # Returns the data size in bits.
        #
        def size
          @data.size << 3
        end

        #
        # Sets the read pointer position in bits.
        #
        def pos=(bits)
          raise BitReaderError, "Pointer position out of data" if bits > self.size

          pbyte = bits >> 3
          pbit = bits - (pbyte << 3)
          @ptr_byte, @ptr_bit = pbyte, pbit
          
          bits
        end

        #
        # Reads _length_ bits as a Fixnum and advances read pointer.
        #
        def read(length)
          n = self.peek(length)
          self.pos += length

          n
        end
        
        #
        # Reads _length_ bits as a Fixnum. Does not advance read pointer.
        #
        def peek(length)
          return BitReaderError, "Invalid read length" unless length > 0 
          return BitReaderError, "Insufficient data" if self.pos + length > self.size

          n = 0
          ptr_byte, ptr_bit = @ptr_byte, @ptr_bit

          while length > 0
            byte = @data[ptr_byte].ord
    
            if length > 8 - ptr_bit
              length -= 8 - ptr_bit
              n |= ( byte & ((1 << (8 - ptr_bit)) - 1) ) << length

              ptr_byte += 1
              ptr_bit = 0
            else
              n |= (byte >> (8 - ptr_bit - length)) & ((1 << length) - 1)
              length = 0
            end
          end

          n
        end

      end
    end

    module ClassMethods
      #
      # Decodes the given data.
      # _stream_:: The data to decode.
      #
      def decode(stream, params = {})
        self.new(params).decode(stream)
      end
      
      #
      # Encodes the given data.
      # _stream_:: The data to encode.
      #
      def encode(stream, params = {})
        self.new(params).encode(stream)
      end
    end

    def initialize(parameters = {})
      @params = parameters
    end
    
    def self.included(receiver)
      receiver.extend(ClassMethods)
    end
  
  end

end

require 'origami/filters/ascii'
require 'origami/filters/lzw'
require 'origami/filters/flate'
require 'origami/filters/runlength'
require 'origami/filters/ccitt'
require 'origami/filters/dct'
require 'origami/filters/jbig2'
require 'origami/filters/jpx'
require 'origami/filters/crypt'

