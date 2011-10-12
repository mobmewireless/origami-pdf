#!/usr/bin/env ruby 

begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../../lib"
  $: << ORIGAMIDIR
  require 'origami'
end
include Origami

INPUTFILE = "attached.txt"
OUTPUTFILE = "#{File.basename(__FILE__, ".rb")}.pdf"

puts "Now generating a new PDF file from scratch!"

# Creating a new file
pdf = PDF.new

# Embedding the file into the PDF.
pdf.attach_file(INPUTFILE, 
  :EmbeddedName => "README.txt", 
  :Filter => :ASCIIHexDecode
)

contents = ContentStream.new
contents.write "File attachment sample",
  :x => 250, :y => 750, :rendering => Text::Rendering::FILL, :size => 30

pdf.append_page Page.new.setContents(contents)

js = <<JS
  this.exportDataObject({cName:"README.txt", nLaunch:2});
JS
pdf.onDocumentOpen Action::JavaScript.new(js)

pdf.save(OUTPUTFILE)

puts "PDF file saved as #{OUTPUTFILE}."

