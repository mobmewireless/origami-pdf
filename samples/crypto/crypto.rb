#!/usr/bin/env ruby 

begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../../lib"
  $: << ORIGAMIDIR
  require 'origami'
end
include Origami

OUTPUTFILE = "#{File.basename(__FILE__, ".rb")}.pdf"

puts "Now generating a new PDF file from scratch!"

# Creates an encrypted document with AES256 and a null password.
pdf = PDF.new.encrypt(:cipher => 'aes', :key_size => 256)

contents = ContentStream.new
contents.write "Crypto sample",
  :x => 350, :y => 750, :rendering => Text::Rendering::STROKE, :size => 30

pdf.append_page Page.new.setContents(contents)

pdf.save(OUTPUTFILE)

puts "PDF file saved as #{OUTPUTFILE}."

