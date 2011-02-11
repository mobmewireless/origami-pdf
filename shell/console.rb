=begin

= File
	console.rb

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

require 'hexdump'

if RUBY_VERSION < '1.9'
  def Kernel.spawn(cmd)
    fork do
      exec(cmd)
    end
  end
end

module Origami

  module Object
    def inspect
      to_s
    end
  end

  unless (RUBY_VERSION < '1.9' and RUBY_PLATFORM =~ /win32/)
    require 'tempfile'

    class Stream
      def edit(editor = 'vim')
        tmpfile = Tempfile.new("origami")
        tmpfile.write(self.data)
        tmpfile.close

        Process.wait Kernel.spawn "#{editor} #{tmpfile.path}"
        
        self.data = File.read(tmpfile.path)
        tmpfile.unlink

        true
      end

      def to_s
        self.data.hexdump
      end
    end
  end
  
  class PDF
     
     class Revision
      def to_s
        colorprint("----------  Body  ----------\n", Colors::BRIGHT_WHITE, true)
        @body.each_value { |obj|
          colorprint("#{obj.reference.to_s.rjust(8,' ')}".ljust(10), Colors::MAGENTA)
          colorprint("#{obj.type}\n", Colors::YELLOW)
        }
        colorprint("---------- Xrefs -----------\n", Colors::BRIGHT_WHITE, true)
        set_fg_color(Colors::BLUE, true) {
          if not @xreftable
            puts "  [x] No xref table found."
          else
            @xreftable.to_s.each_line { |line|
              puts "  " + line
            }
          end
        }
        colorprint("---------- Trailer ---------\n", Colors::BRIGHT_WHITE, true) 
        if not @trailer.dictionary
          set_fg_color(Colors::BLUE, true) {
            puts "  [x] No trailer found."
          }
        else
          @trailer.dictionary.each_pair { |entry, value|
            colorprint("  [*] ", Colors::MAGENTA)
            colorprint("#{entry.to_s}: ", Colors::YELLOW)
            colorprint("#{value.to_s}\n", Colors::RED)
          }
          colorprint("  [+] ", Colors::MAGENTA)
          colorprint("startxref: ", Colors::YELLOW)
          colorprint("#{@trailer.startxref}\n", Colors::RED)
        end
      end
      
      def inspect
        to_s
      end
     end
    
    def to_s
      puts
      
      colorprint("---------- Header ----------\n", Colors::BRIGHT_WHITE, true)
      colorprint("  [+] ", Colors::MAGENTA)
      colorprint("Major version: ", Colors::YELLOW)
      colorprint("#{@header.majorversion}\n", Colors::RED)
      colorprint("  [+] ", Colors::MAGENTA)
      colorprint("Minor version: ", Colors::YELLOW)
      colorprint("#{@header.minorversion}\n", Colors::RED)
      
      @revisions.each { |revision|
        revision.to_s
      }
      puts
    end
    
    def inspect
      to_s
    end
  end
end

