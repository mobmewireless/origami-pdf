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

  unless RUBY_VERSION < '1.9'
    require 'tempfile'

    class Stream
      def edit(editor = ENV['EDITOR'])
        tmpfile = Tempfile.new("origami")
        tmpfile.write(self.data)
        tmpfile.close

        Process.wait Kernel.spawn "#{editor} #{tmpfile.path}"
        
        self.data = File.read(tmpfile.path)
        tmpfile.unlink

        true
      end

      def inspect
        self.data.hexdump
      end
    end

    class Page
      def edit 
        self.Contents.edit
      end
    end
  end
  
  class PDF

    if defined?(PDF::JavaScript::Engine)
      class JavaScript::Engine
        def shell
          while (print 'js> '; line = gets)
            begin
              puts exec(line)
            rescue V8::JSError => e
              puts "Error: #{e.message}"
            end
          end
        end
      end
    end
     
     class Revision
      def to_s
        Console.colorprint("----------  Body  ----------\n", Console::Colors::WHITE, true)
        @body.each_value { |obj|
          Console.colorprint("#{obj.reference.to_s.rjust(8,' ')}".ljust(10), Console::Colors::MAGENTA)
          Console.colorprint("#{obj.type}\n", Console::Colors::YELLOW)
        }
        #colorprint("---------- Xrefs -----------\n", Colors::BRIGHT_WHITE, true)
        #set_fg_color(Colors::BLUE, true) {
        #  if not @xreftable
        #    puts "  [x] No xref table found."
        #  else
        #    @xreftable.to_s.each_line { |line|
        #      puts "  " + line
        #    }
        #  end
        #}
        Console.colorprint("---------- Trailer ---------\n", Console::Colors::WHITE, true) 
        if not @trailer.dictionary
          Console.set_fg_color(Console::Colors::BLUE, true) {
            puts "  [x] No trailer found."
          }
        else
          @trailer.dictionary.each_pair { |entry, value|
            Console.colorprint("  [*] ", Console::Colors::MAGENTA)
            Console.colorprint("#{entry.to_s}: ", Console::Colors::YELLOW)
            Console.colorprint("#{value.to_s}\n", Console::Colors::RED)
          }
          Console.colorprint("  [+] ", Console::Colors::MAGENTA)
          Console.colorprint("startxref: ", Console::Colors::YELLOW)
          Console.colorprint("#{@trailer.startxref}\n", Console::Colors::RED)
        end
      end
      
      def inspect
        to_s
      end
     end
    
    def to_s
      puts
      
      Console.colorprint("---------- Header ----------\n", Console::Colors::WHITE, true)
      Console.colorprint("  [+] ", Console::Colors::MAGENTA)
      Console.colorprint("Major version: ", Console::Colors::YELLOW)
      Console.colorprint("#{@header.majorversion}\n", Console::Colors::RED)
      Console.colorprint("  [+] ", Console::Colors::MAGENTA)
      Console.colorprint("Minor version: ", Console::Colors::YELLOW)
      Console.colorprint("#{@header.minorversion}\n", Console::Colors::RED)
      
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

