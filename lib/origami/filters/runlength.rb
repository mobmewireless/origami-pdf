=begin

= File
	filters/runlength.rb

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
  
  module Filter
    
    class InvalidRunLengthDataError < Exception #:nodoc:
    end
    
    #
    # Class representing a Filter used to encode and decode data using RLE compression algorithm.
    #
    class RunLength
      include Filter
      
      EOD = 128 #:nodoc:
      
      #
      # Encodes data using RLE compression method.
      # _stream_:: The data to encode.
      #
      def encode(stream)

        result = ""
        i = 0

        while i < stream.size
          
          #
          # How many identical bytes coming?
          #
          length = 1
          while i+1 < stream.size and length < EOD and stream[i] == stream[i+1]
            length = length + 1
            i = i + 1
          end

          #
          # If more than 1, then compress them.
          #
          if length > 1
            result << (257 - length).chr << stream[i,1]

          #
          # Otherwise how many different bytes to copy ?
          #
          else
            j = i
            while j+1 < stream.size and (j - i + 1) < EOD and stream[j] != stream[j+1]
              j = j + 1
            end

            length = j - i
            result << length.chr << stream[i, length+1]

            i = j
          end

          i = i + 1
        end

        result << EOD.chr
      end


      #
      # Decodes data using RLE decompression method.
      # _stream_:: The data to decode.
      #
      def decode(stream)
        raise InvalidRunLengthDataError, "No end marker" unless stream.include?(EOD.chr)
        
        i = 0
        result = ""
        until stream[i].ord == EOD do
        
          length = stream[i].ord
          if length < EOD
            result << stream[i + 1, length + 1]
            i = i + length + 2
          else
            result << stream[i + 1,1] * (257 - length)
            i = i + 2
          end
          
        end
        
        result
      end

    end
  end
end

