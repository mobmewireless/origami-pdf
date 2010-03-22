require 'optparse'

class OptParser
    def self.parse(args)
        options = {}
        opts = OptionParser.new do |opts|
            opts.banner = "Usage: #{$0} [options] <arguments>"

            opts.on("-t", "--type <fast,deep>", "Type") do |t|
                options[:type] = t
            end
            

            opts.on("-o", "--output <txt,html>", "Output") do |o|
                options[:output] = o
            end

            opts.on_tail("-h", "--help", "Show this message") do
                puts opts
                exit
            end
        end
        opts.parse!(args)

        options[:type]   = "fast" unless %w{fast deep}.include?(options[:type])
        options[:output] = "txt"  unless %w{txt html}.include?(options[:output])

        options
    end
end

@options = OptParser.parse(ARGV)

def get_params(arg)
  @options[arg]
end
