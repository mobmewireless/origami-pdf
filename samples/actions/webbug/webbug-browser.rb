#!/usr/bin/ruby 

begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../../../lib"
  $: << ORIGAMIDIR
  require 'origami'
end
include Origami

OUTPUTFILE = "webbug-browser.pdf"

puts "Now generating a new bugged PDF file from scratch!"

URL = "http://localhost/webbug-browser.html"

pdf = PDF.new

contents = ContentStream.new
contents.write "webbug-browser.pdf",
  :x => 270, :y => 750, :rendering => Text::Rendering::STROKE, :size => 30

contents.write "When opened, this PDF connects to \"home\"",
  :x => 156, :y => 690, :rendering => Text::Rendering::FILL, :size => 15

contents.write "Click \"Allow\":",
  :x => 156, :y => 670, :size => 12

contents.write "  1. Starts your default browser",
  :x => 156, :y => 650, :size => 12 

contents.write "  1. Connects to #{URL}",
  :x => 156, :y => 630, :size => 12

contents.write "Comments:",
  :x => 75, :y => 580, :rendering => Text::Rendering::FILL_AND_STROKE, :size => 14

content = <<-EOS
Windows:
  - Foxit : opens the default browser without any user confirmation (!)
  - Acrobat Reader 8: a pop-up spreads asking if it can connect, then Internet Explorer is connected.


Mac:
  - Preview: nothing happens
  - Acrobat Reader 8: a pop-up spreads asking if it can connect, then Safari is connected

Linux:
  - poppler: nothing happens
  - Acrobat Reader [7, 8]: a pop-up spreads asking if it can connect


EOS

contents.write content,
  :x => 75, :y => 560, :rendering => Text::Rendering::FILL


page = Page.new.setContents( contents )
pdf.append_page(page)

# Starting action
pdf.onDocumentOpen Action::URI.new(URL)

pdf.save(OUTPUTFILE)

puts "PDF file saved as #{OUTPUTFILE}."
