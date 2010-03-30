#!/usr/bin/ruby 
#
# - /OpenAction
#     - execute directly the expected command
#     - GoTo <page> to trigger a /AA on that page
# - Annotation triggering an action when page is visible
# - Registering a script in /Names dictionnaries
# - Requirement handlers (12.10) -> TODO, not working currently
#
# - Using another embedded PDF, any of the previous method, but a
#   GoToE to jump to the embedded PDF
#
# objet visible sur la 1ère page
#

begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../.."
  $: << ORIGAMIDIR
  require 'origami'
end
include Origami

OUTPUTFILE = "#{File.basename(__FILE__, ".rb")}"

######
# Injected functions to trigger our javascript when the document is
# opened.
######
def openaction(pdf, action)

  pdf.onDocumentOpen( action )

  return pdf

end


def gotoAA(pdf, action)

    page = pdf.pages[ rand(pdf.pages.size) ]
    page.onOpen( action )

    goto = Action::GoTo.new( :D => [ page, :Fit] )
    pdf.onDocumentOpen( goto )

    return pdf 

end

def annotPV(pdf, action)

    annot = Annotation::Screen.new
    annot.Rect = Rectangle[:llx => 350, :lly => 700, :urx => 415, :ury => 640]
    annot.onPageVisible( action )

    pdf.pages[ 0 ].add_annot(annot)

    return pdf
end


def register(pdf, action)

  pdf.register(Names::Root::JAVASCRIPT, "welcome", action)

  return pdf
end



######
# Creating PDF file
######
def populate(method, desc)

  puts "Now generating a new PDF file from scratch!"
  pdf = PDF.new

  contents = ContentStream.new
  contents.write "#{method}.pdf",
    :x => 350, :y => 750, :rendering => Text::Rendering::STROKE, :size => 30
  contents.write "A JS action is performed when this doc is opened.",
    :x => 186, :y => 690, :rendering => Text::Rendering::FILL, :size => 15

  contents.write "Method: #{desc}",
    :x => 186, :y => 660, :rendering => Text::Rendering::FILL, :size => 15

  page = Page.new
  page.Contents = contents
  pdf.append_page(page)

  page = Page.new
  contents = ContentStream.new
  contents.write "Welcome on page 2",
    :x => 186, :y => 690, :rendering => Text::Rendering::FILL, :size => 15
  page.Contents = contents
  pdf.append_page(page)

  page = Page.new
  contents = ContentStream.new
  contents.write "Welcome on page 3",
    :x => 186, :y => 690, :rendering => Text::Rendering::FILL, :size => 15
  page.Contents = contents
  pdf.append_page(page)


  js = Action::JavaScript.new("app.alert(\"Method: #{desc}\")")


  case method

      when "openaction"
        pdf = openaction(pdf, js)

      when "gotoAA"
        pdf = gotoAA(pdf, js)

      when "annotPV"
        pdf = annotPV(pdf, js)

      when "register"
        pdf = register(pdf, js)
    
      else
        puts "unknown method\n"

  end

  pdf.saveas("#{method}.pdf")
  puts "PDF file saved as #{method}.pdf."

end

######
# PLAYGROUND
######

populate("openaction", "/OpenAction")
populate("gotoAA", "/OpenAction(/GoTo page(rand)) & /AA on that page")
populate("annotPV", "/AA when annotation becomes visible on 1st page")
populate("register", "Add the script to the document names dictionary")

