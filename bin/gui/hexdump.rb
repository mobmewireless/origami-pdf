=begin

= File
	hexdump.rb

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

class String #:nodoc:
  
  def hexdump(bytesperline = 16, upcase = true, offsets = true)
    
    dump = ""
    counter = 0
    
    while counter < length
      
      offset = sprintf("%010u", counter)
      
      linelen = (counter < length - bytesperline) ? bytesperline : (length - counter)
      bytes = ""
      linelen.times do |i|
        
        byte = self[counter + i].ord.to_s(16)
        if byte.size < 2 then byte.insert(0, "0") end
        bytes << byte
        bytes << " " unless i == bytesperline - 1
        
      end

      ascii = self[counter, linelen].ascii_print
      
      if upcase
        offset.upcase!
        bytes.upcase!
      end
      
      dump << "#{offset if offsets}  #{bytes.to_s.ljust(bytesperline * 3 - 1)}  #{ascii}\n"
      
      counter += bytesperline
      
    end

    dump
  end
  
  def ascii_print

    printable = ""
    self.each_byte do |c|
      if c >= ' '[0].ord && c <= '~'[0].ord then printable << c else printable << '.' end
    end

    printable
  end
  
end
