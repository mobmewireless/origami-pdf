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
contents.write "Pass your mouse over the yellow square",
  :x => 250, :y => 750, :size => 15

page.setContents( contents )

onpageopen = Action::JavaScript.new "app.alert('Page Opened');"
onpageclose = Action::JavaScript.new "app.alert('Page Closed');"
ondocumentopen = Action::JavaScript.new "app.alert('Document is opened');"
ondocumentclose = Action::JavaScript.new "app.alert('Document is closing');"
onmouseover =Action::JavaScript.new "app.alert('Mouse over');"
onmouseleft =Action::JavaScript.new "app.alert('Mouse left');"
onmousedown = Action::JavaScript.new "app.alert('Mouse down');"
onmouseup = Action::JavaScript.new "app.alert('Mouse up');"
onparentopen = Action::JavaScript.new "app.alert('Parent page has opened');"
onparentclose = Action::JavaScript.new "app.alert('Parent page has closed');"
onparentvisible = Action::JavaScript.new "app.alert('Parent page is visible');"
onparentinvisible = Action::JavaScript.new "app.alert('Parent page is no more visible');"
namedscript = Action::JavaScript.new "app.alert('Names directory script');"

pdf.onDocumentOpen(ondocumentopen)
pdf.onDocumentClose(ondocumentclose)
page.onOpen(onpageopen).onClose(onpageclose)

pdf.register(Names::Root::JAVASCRIPT, "test", namedscript)

rect_coord = Rectangle[:llx => 350, :lly => 700, :urx => 415, :ury => 640]

# Just draw a yellow rectangle.
rect = Annotation::Square.new
rect.Rect = rect_coord
rect.IC = [ 255, 255, 0 ]

# Creates a new annotation which will catch mouse actions.
annot = Annotation::Screen.new
annot.Rect = rect_coord

# Bind the scripts to numerous triggers.
annot.onMouseOver(onmouseover)
annot.onMouseOut(onmouseleft)
annot.onMouseDown(onmousedown)
annot.onMouseUp(onmouseup)
annot.onPageOpen(onparentopen)
annot.onPageClose(onparentclose)
annot.onPageVisible(onparentvisible)
annot.onPageInvisible(onparentinvisible)

page.add_annot(annot)
page.add_annot(rect)

pdf.append_page(page)

# Save the resulting file.
pdf.save(OUTPUTFILE)

puts "PDF file saved as #{OUTPUTFILE}."
