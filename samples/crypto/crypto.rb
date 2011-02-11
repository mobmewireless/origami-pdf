#!/usr/bin/env ruby 

begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../.."
  $: << ORIGAMIDIR
  require 'origami'
end
include Origami

OUTPUTFILE = "#{File.basename(__FILE__, ".rb")}.pdf"
USERPASSWD = ""
OWNERPASSWD = ""

puts "Now generating a new PDF file from scratch!"

# Creates an encrypted document with AES128 (256 not implemented yet) and a null password.
pdf = PDF.new.encrypt(USERPASSWD, OWNERPASSWD, :Algorithm => :AES )

contents = ContentStream.new
contents.write "Crypto sample",
  :x => 350, :y => 750, :rendering => Text::Rendering::STROKE, :size => 30

pdf.append_page Page.new.setContents(contents)

pdf.save(OUTPUTFILE)

puts "PDF file saved as #{OUTPUTFILE}."
