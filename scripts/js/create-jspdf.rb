#!/usr/bin/env ruby 

$: << ".."
require 'getopt.rb'

begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../.."
  $: << ORIGAMIDIR
  require 'origami'
end
include Origami

pdf, output_filename = get_params()

if ARGV.length == 0
  puts "Missing argument: <jsscriptfile>"
  exit
end

JSCRIPTFILE = ARGV[0]
OUTPUTFILE = output_filename

puts "Now generating a new PDF file from scratch!"

contents = ContentStream.new
contents.write OUTPUTFILE,
  :x => 350, :y => 750, :rendering => Text::Rendering::STROKE, :size => 30 

pdf.pages.first.setContents(contents)

######
# PLAYGROUND
######

jscript = File.open(JSCRIPTFILE).read

#
# Create a new JavaScript action from a flate encoded stream.
#
jsaction = Action::JavaScript.new(Stream.new(jscript, :Filter => :FlateDecode))

pdf.onDocumentOpen(jsaction)

# Saving the resulting PDF
pdf.save(OUTPUTFILE)

puts "PDF file saved as #{OUTPUTFILE}."
