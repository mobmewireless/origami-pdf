=begin

= File
	filters/ascii.rb

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
    
    class InvalidASCIIHexStringError < InvalidFilterDataError #:nodoc:
    end
    
    #
    # Class representing a filter used to encode and decode data written into hexadecimal.
    #
    class ASCIIHex
      include Filter
      
      EOD = ">"  #:nodoc:
      
      #
      # Encodes given data into upcase hexadecimal representation.
      # _stream_:: The data to encode.
      #
      def encode(stream)
        stream.unpack("H2" * stream.size).join.upcase
      end
      
      #
      # Decodes given data writen into upcase hexadecimal representation.
      # _string_:: The data to decode.
      #
      def decode(string)
        
        input = string.include?(?>) ? string[0..string.index(?>) - 1] : string
        digits = input.delete(" \f\t\r\n\0").split(/(..)/).delete_if{|digit| digit.empty?}
        
        if not digits.all? { |d| d =~ /[a-fA-F0-9]{1,2}/ }
          raise InvalidASCIIHexStringError, input
        end
        
        digits.pack("H2" * digits.size)
      end
      
    end
    
    class InvalidASCII85StringError < InvalidFilterDataError #:nodoc:
    end
    
    #
    # Class representing a filter used to encode and decode data written in base85 encoding.
    #
    class ASCII85
      include Filter
      
      EOD = "~>" #:nodoc:
      
      #
      # Encodes given data into base85.
      # _stream_:: The data to encode.
      #
      def encode(stream)
        
        i = 0
        code = ""
        input = stream.dup
        
        while i < input.size do
          
          if input.length - i < 4
            addend = 4 - (input.length - i)
            input << "\0" * addend
          else
            addend = 0
          end
          
          inblock = (input[i].ord * 256**3 + input[i+1].ord * 256**2 + input[i+2].ord * 256 + input[i+3].ord)
          outblock = ""
          
          5.times do |p|
            c = inblock / 85 ** (4 - p)
            outblock << ("!"[0].ord + c).chr
            
            inblock -= c * 85 ** (4 - p)
          end
          
          outblock = "z" if outblock == "!!!!!" and addend == 0
          
          if addend != 0
            outblock = outblock[0,(4 - addend) + 1]
          end
          
          code << outblock
          
          i = i + 4
        end

        code
      end
      
      #
      # Decodes the given data encoded in base85.
      # _string_:: The data to decode.
      #
      def decode(string)
        
        input = (string.include?(EOD) ? string[0..string.index(EOD) - 1] : string).delete(" \f\t\r\n\0")
        
        i = 0
        result = ""
        while i < input.size do
          
          outblock = ""

          if input[i].ord == "z"[0].ord
            inblock = 0
            codelen = 1
          else
            
            inblock = 0
            codelen = 5
            
            if input.length - i < 5
              raise InvalidASCII85StringError.new("Invalid length", result) if input.length - i == 1
              
              addend = 5 - (input.length - i)
              input << "u" * addend
            else
              addend = 0
            end
          
            # Checking if this string is in base85
            5.times do |j|
              if input[i+j].ord > "u"[0].ord or input[i+j].ord < "!"[0].ord
                raise InvalidASCII85StringError.new(
                  "Invalid character sequence: #{input[i,5].inspect}",
                  result
                )
              else
                inblock += (input[i+j].ord - "!"[0].ord) * 85 ** (4 - j)
              end
            end
          
            
            raise InvalidASCII85StringError.new(
              "Invalid value (#{inblock}) for block #{input[i,5].inspect}",
              result
            ) if inblock >= 2**32
          
          end
        
          4.times do |p|
            c = inblock / 256 ** (3 - p)
            outblock << c.chr
            
            inblock -= c * 256 ** (3 - p)
          end
          
          if addend != 0
            outblock = outblock[0, 4 - addend]
          end
        
          result << outblock
          
          i = i + codelen
        end
        
        result
      end

    end
  end
end

