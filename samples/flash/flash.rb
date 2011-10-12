#!/usr/bin/env ruby 

begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../../lib"
  $: << ORIGAMIDIR
  require 'origami'
end
include Origami

INPUTFILE = "helloworld.swf"
OUTPUTFILE = "#{File.basename(__FILE__, ".rb")}.pdf"

puts "Now generating a new PDF file from scratch!"

# Creating a new file
pdf = PDF.new.append_page(page = Page.new)

# Embedding the SWF file into the PDF.
swf = pdf.attach_file(INPUTFILE)

# Creating a Flash annotation on the page.
annot = page.add_flash_application(swf, :windowed => true, :navigation_pane => true, :toolbar => true)

# Setting the player position on the page.
annot.Rect = Rectangle.new(204, 573, 403, 718)

pdf.save(OUTPUTFILE)

puts "PDF file saved as #{OUTPUTFILE}."
