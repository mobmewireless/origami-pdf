begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../../lib"
  $: << ORIGAMIDIR
  require 'origami'
end
include Origami

require 'console.rb'
require 'readline'

OPENSSL_SUPPORT = (defined?(OpenSSL).nil?) ? 'no' : 'yes'
JAVASCRIPT_SUPPORT = (defined?(PDF::JavaScript::Engine).nil?) ? 'no' : 'yes'
DEFAULT_BANNER = "Welcome to the PDF shell (Origami release #{Origami::VERSION}) [OpenSSL: #{OPENSSL_SUPPORT}, JavaScript: #{JAVASCRIPT_SUPPORT}]\n\n"

def set_completion

  completionProc = proc { |input|
    bind = IRB.conf[:MAIN_CONTEXT].workspace.binding
    
    validClasses = Origami.constants.reject do |name| 
      obj = Origami.const_get(name)
      (not obj.is_a?(Module) and not obj.is_a?(Class)) or obj <= Exception
    end

    case input

#    # Classes
#    when /^([A-Z][^:\.\(]*)$/
#      classname = $1
#      candidates = validClasses
#      return candidates.grep(/^#{classname}/)
#
#    # Methods
#    when /^([^:.\(]*)\.([^:.]*)$/
#      classname = $1
#      method = Regexp.quote($2)
#      candidates = []
#      if validClasses.include? $1
#        begin
#          candidates = eval("Origami::#{classname}.methods", bind)
#        rescue Exception
#          candidates = []
#        end
#        return candidates.grep(/^#{method}/).collect{|e| classname + "." + e}
#      else
#        begin
#          var = $1.dup
#          classname = eval("#{classname}.class", bind).to_s
#          if validClasses.include?(classname.split("::").last)
#            candidates = eval("#{classname}.public_instance_methods", bind)
#          end
#        rescue Exception => e
#          candidates = []
#        end
#        return candidates.grep(/^#{method}/).collect{|e| var + "." + e}
#      end
#
      # Mod/class
      when /^(.*)::$/
        begin
          space = eval("Origami::#{$1}", bind)
        rescue Exception
          return []
        end

        return space.constants.reject{|const| space.const_get(const) <= Exception}

      when /^(.*).$/
        begin 
          space = eval($1, bind)
        rescue
          return []
        end

        return space.public_methods
    end
  }

  if Readline.respond_to?("basic_word_break_characters=")
    Readline.basic_word_break_characters= " \t\n\"\\'`><=;|&{("
  end
  Readline.completion_append_character = nil
  Readline.completion_proc = completionProc

end

def set_prompt

  IRB.conf[:PROMPT][:PDFSH] = {
    :PROMPT_C => "?>> ",
    :RETURN => "%s\n",
    :PROMPT_I => ">>> ",
    :PROMPT_N => ">>> ",
    :PROMPT_S => nil
  }

  IRB.conf[:PROMPT_MODE] = :PDFSH

end

Console.colorprint(DEFAULT_BANNER, Console::Colors::GREEN)
#set_completion
set_prompt

