=begin

= File
	parser.rb

= Info
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

require 'strscan'

module Origami

  module Console
  
    if RUBY_PLATFORM =~ /win32/ or RUBY_PLATFORM =~ /mingw32/
      require "Win32API"
    
      getStdHandle = Win32API.new("kernel32", "GetStdHandle", ['L'], 'L')
      @@setConsoleTextAttribute = Win32API.new("kernel32", "SetConsoleTextAttribute", ['L', 'N'], 'I')

      @@hOut = getStdHandle.call(-11)
    end

    module Colors #:nodoc;
      if RUBY_PLATFORM =~ /win32/ or RUBY_PLATFORM =~ /mingw32/
        BLACK     = 0
        BLUE      = 1
        GREEN     = 2
        CYAN      = 3
        RED       = 4
        MAGENTA   = 5
        YELLOW    = 6
        GREY      = 7
        WHITE     = 8
      else
        GREY      = '0;0'
        BLACK     = '0;30'
        RED       = '0;31'
        GREEN     = '0;32'
        YELLOW    = '0;33'
        BLUE      = '0;34'
        MAGENTA   = '0;35'
        CYAN      = '0;36'
        WHITE     = '0;37'
        BRIGHT_GREY       = '1;30'
        BRIGHT_RED        = '1;31'
        BRIGHT_GREEN      = '1;32'
        BRIGHT_YELLOW     = '1;33'
        BRIGHT_BLUE       = '1;34'
        BRIGHT_MAGENTA    = '1;35'
        BRIGHT_CYAN       = '1;36'
        BRIGHT_WHITE      = '1;37'
      end
    end

    def self.set_fg_color(color, bright = false, fd = STDOUT) #:nodoc:
      if RUBY_PLATFORM =~ /win32/ or RUBY_PLATFORM =~ /mingw32/
        if bright then color |= Colors::WHITE end
        @@setConsoleTextAttribute.call(@@hOut, color)
        yield
        @@setConsoleTextAttribute.call(@@hOut, Colors::GREY)
      else
        col, nocol = [color, Colors::GREY].map! { |key| "\033[#{key}m" }
        fd << col
        yield
        fd << nocol
      end
    end

    unless RUBY_PLATFORM =~ /win32/ or RUBY_PLATFORM =~ /mingw32/
      def self.colorize(text, color, bright = false)
        col, nocol = [color, Colors::GREY].map! { |key| "\033[#{key}m" }
        "#{col}#{text}#{nocol}"
      end
    end

    def self.colorprint(text, color, bright = false, fd = STDOUT) #:nodoc:
      set_fg_color(color, bright, fd) {
        fd << text
      }    
    end

  end
  
  class Parser #:nodoc:

    class ParsingError < Exception #:nodoc:
    end
   
    #
    # Do not output debug information.
    #
    VERBOSE_QUIET = 0
    
    #
    # Output some useful information.
    #
    VERBOSE_INFO = 1
    
    #
    # Output debug information.
    #
    VERBOSE_DEBUG = 2
    
    #
    # Output every objects read
    # 
    VERBOSE_INSANE = 3
    
    attr_accessor :options
    
    def initialize(options = {}) #:nodoc:
      
      #Default options values
      @options = 
      { 
        :verbosity => VERBOSE_INFO, # Verbose level.
        :ignore_errors => true,     # Try to keep on parsing when errors occur.
        :callback => Proc.new {},   # Callback procedure whenever a structure is read.
        :logger => STDERR,          # Where to output parser messages.
        :colorize_log => true       # Colorize parser output?
      }
     
      @options.update(options)
    end

    def parse(stream)
      data = 
      if stream.respond_to? :read
        if ''.respond_to? :force_encoding
          StringScanner.new(stream.read.force_encoding('binary')) # 1.9 compat
        else
          StringScanner.new(stream.read)
        end
      elsif stream.is_a? ::String
        @filename = stream
        if ''.respond_to? :force_encoding
          StringScanner.new(File.open(stream, "r", :encoding => 'binary').binmode.read)
        else
          StringScanner.new(File.open(stream, "r").binmode.read)
        end
      elsif stream.is_a? StringScanner
        stream
      else
        raise TypeError
      end
    
      @logger = @options[:logger]
      @data = data
      @data.pos = 0
    end

    def parse_object(pos = @data.pos) #:nodoc:
      @data.pos = pos
      
      begin
        obj = Object.parse(@data)
        return if obj.nil?
        
        trace "Read #{obj.type} object#{
          if obj.type != obj.real_type
            " (" + obj.real_type.to_s.split('::').last + ")" 
          end
        }, #{obj.reference}"

        @options[:callback].call(obj)
        obj

      rescue UnterminatedObjectError => e
        error e.message
        obj = e.obj

        Object.skip_until_next_obj(@data)
        @options[:callback].call(obj)
        obj

      rescue Exception => e
        error "Breaking on: #{(@data.peek(10) + "...").inspect} at offset 0x#{@data.pos.to_s(16)}"
        error "Last exception: [#{e.class}] #{e.message}"
        if not @options[:ignore_errors]
          error "Manually fix the file or set :ignore_errors parameter."
          raise
        end

        debug 'Skipping this indirect object.'
        raise if not Object.skip_until_next_obj(@data)
            
        retry
      end
    end
    
    def parse_xreftable(pos = @data.pos) #:nodoc:
      @data.pos = pos

      begin
        info "...Parsing xref table..."
        xreftable = XRef::Section.parse(@data)
        @options[:callback].call(xreftable)

        xreftable
      rescue Exception => e
        debug "Exception caught while parsing xref table : " + e.message
        warn "Unable to parse xref table! Xrefs might be stored into an XRef stream."

        @data.pos -= 'trailer'.length unless @data.skip_until(/trailer/).nil?
      end
    end
    
    def parse_trailer(pos = @data.pos) #:nodoc:
      @data.pos = pos

      begin
        info "...Parsing trailer..."
        trailer = Trailer.parse(@data)

        @options[:callback].call(trailer)
        trailer
       
      rescue Exception => e
        debug "Exception caught while parsing trailer : " + e.message
        warn "Unable to parse trailer!"
            
        abort("Manually fix the file or set :ignore_errors parameter.") if not @options[:ignore_errors]

        raise
      end
    end

    def target_filename
      @filename
    end

    def target_filesize
      @data.string.size if @data
    end

    def target_data
      @data.string.dup if @data
    end

    private
 
    def error(str = "") #:nodoc:
      if @options[:colorize_log]
        Console.colorprint("[error] #{str}\n", Console::Colors::RED, false, @logger)
      else
        @logger.puts "[error] #{str}"
      end
    end

    def warn(str = "") #:nodoc:
      if @options[:verbosity] >= VERBOSE_INFO
        if @options[:colorize_log]
          Console.colorprint("[info ] Warning: #{str}\n", Console::Colors::YELLOW, false, @logger) 
        else
          @logger.puts "[info ] #{str}"
        end
      end
    end

    def info(str = "") #:nodoc:
      if @options[:verbosity] >= VERBOSE_INFO 
        if @options[:colorize_log]
          Console.colorprint("[info ] ", Console::Colors::GREEN, false, @logger)
          @logger.puts str
        else
          @logger.puts "[info ] #{str}"
        end
      end
    end
    
    def debug(str = "") #:nodoc:
      if @options[:verbosity] >= VERBOSE_DEBUG
        if @options[:colorize_log]
          Console.colorprint("[debug] ", Console::Colors::MAGENTA, false, @logger)
          @logger.puts str 
        else
          @logger.puts "[debug] #{str}"
        end
      end
    end
    
    def trace(str = "") #:nodoc:
      if @options[:verbosity] >= VERBOSE_INSANE
        if @options[:colorize_log]
          Console.colorprint("[trace] ", Console::Colors::CYAN, false, @logger)
          @logger.puts str
        else
          @logger.puts "[trace] #{str}"
        end
      end
    end
  end
end

