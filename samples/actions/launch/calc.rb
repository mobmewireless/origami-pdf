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

puts "Generating a pdf launching calc on several OS!!"

pdf = PDF.new

# Reader7.0  
# A popup firstly says it cannot open the specified file. Then the
# file is opened once the "Open" button is clicked...

# Reader8.0
# It "opens" the file, but does not execute it. By default, it seems
# it is passed to the default browser.
# Only local files can be opened this way.
# If the file does not exist, it displays the content of the current
# directory

cmd = FileSpec.new
cmd.Unix = "/usr/bin/xcalc"
cmd.Mac = "/Applications/Calculator.app"
cmd.DOS = "C:\\\\WINDOWS\\\\system32\\\\calc.exe"

action = Action::Launch.new
action.F = cmd

pdf.onDocumentOpen( action )

contents = ContentStream.new
contents.write OUTPUTFILE,
  :x => 350, :y => 750, :rendering => Text::Rendering::STROKE, :size => 30

contents.write "This page is empty but it should start calc :-D",
  :x => 233, :y => 690, :rendering => Text::Rendering::FILL, :size => 15, :color => Graphics::Color::RGB.new(0, 150, 0)

contents.write "Dont be afraid of the pop-ups, just click them...",
  :x => 233, :y => 670, :size => 15

contents.write "Comments:",
  :x => 75, :y => 620, :rendering => Text::Rendering::FILL_AND_STROKE, :size => 14

content = <<-EOS
Windows:
  - Foxit 2: runs calc.exe at the document opening without any user confirmation message (!)      
  - Acrobat Reader *:
      1. popup proposing to open \"calc.exe\" (warning)
      2.  starts  \"calc.exe\"

Mac:
  - Preview does not support PDF keyword /Launch
  - Acrobat Reader 8.1.2: starts Calculator.app

Linux:
  ! Assumes xcalc is in /usr/bin/xcalc
  - poppler: does not support PDF keyword /Launch
  - Acrobat Reader 7: 
      1. popup telling it can not open \"xcalc\" (dumb reasons)
      2. popup proposing to open \"xcalc\" (warning)
      3. starts  \"xcalc\"
  - Acrobat Reader 8.1.2: based on xdg-open
      - if you are running KDE, Gnome or xfce, xcalc is started after a popup
      - otherwise, your brower is started and tries to download \"xcalc\"

Note:
For Linux and Mac, no argument can be given to the command...

EOS

contents.write content,
  :x => 75, :y => 600, :rendering => Text::Rendering::FILL

page = Page.new.setContents( contents )
pdf.append_page( page )

pdf.save(OUTPUTFILE)
puts "PDF file saved as #{OUTPUTFILE}."

