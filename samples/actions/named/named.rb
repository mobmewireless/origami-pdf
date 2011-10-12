#!/usr/bin/ruby 

begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../../../lib"
  $: << ORIGAMIDIR
  require 'origami'
end
include Origami

OUTPUTFILE = "#{File.basename(__FILE__, ".rb")}.pdf"

puts "Now generating a new PDF file from scratch!"

pdf = PDF.new

page = Page.new

contents = ContentStream.new
contents.write OUTPUTFILE,
  :x => 350, :y => 750, :rendering => Text::Rendering::STROKE, :size => 30

page.Contents = contents
pdf.append_page(page)

pdf.onDocumentOpen Action::Named.new(Action::Named::PRINT)

pdf.save(OUTPUTFILE)

puts "PDF file saved as #{OUTPUTFILE}."
