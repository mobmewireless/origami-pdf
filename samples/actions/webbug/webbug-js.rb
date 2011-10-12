#!/usr/bin/ruby 

begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../../../lib"
  $: << ORIGAMIDIR
  require 'origami'
end
include Origami

OUTPUTFILE = "webbug-js.pdf"
JSCRIPTFILE = "submitform.js"

puts "Now generating a new PDF file from scratch!"

contents = ContentStream.new.setFilter(:FlateDecode)
contents.write OUTPUTFILE,
  :x => 300, :y => 750, :rendering => Text::Rendering::STROKE, :size => 30

contents.write "This PDF tries to connect through JavaScript calls :-D",
  :x => 186, :y => 690, :rendering => Text::Rendering::FILL, :size => 15

contents.write "The script first tries to run your browser, then it connects with the Reader.",
  :x => 186, :y => 670, :size => 15

contents.write "Comments:",
  :x => 75, :y => 620, :rendering => Text::Rendering::FILL_AND_STROKE, :size => 14

content = <<-EOS
Windows:
  - Acrobat Reader 8: Same behavior as with webbug-browser.pdf and webbug-reader.pdf.
  - Foxit: Same behavior as with webbug-browser.pdf and webbug-reader.pdf, at the difference a popup appears
      to ask for user confirmation before launching the browser. However the reader still connects to the site without
      confirmation, as with webbug-reader.pdf

Mac:

Linux:
  - Acrobat Reader 8: same behavior as Windows version.
  - poppler-based viewers: not interpreting JavaScript : nothing happens.
  
EOS

contents.write content,
  :x => 75, :y => 600, :rendering => Text::Rendering::FILL

# A JS script to execute at the opening of the document 
jscript = File.open(JSCRIPTFILE).read

pdf = PDF.new

page = Page.new
page.Contents = contents

pdf.append_page(page)

# Create a new action based on the script, compressed with zlib
jsaction = Action::JavaScript.new( Stream.new(jscript,:Filter => :FlateDecode) )

# Add the script into the document names dictionary. Any scripts registered here will be executed at the document opening (with no OpenAction implied).
pdf.register(Names::Root::JAVASCRIPT, "Update", jsaction)

# Save the resulting file
pdf.save(OUTPUTFILE)

puts "PDF file saved as #{OUTPUTFILE}."
