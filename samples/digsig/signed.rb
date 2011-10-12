#!/usr/bin/ruby 

require 'openssl'

begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../../lib"
  $: << ORIGAMIDIR
  require 'origami'
end
include Origami

OUTPUTFILE = "#{File.basename(__FILE__, ".rb")}.pdf"
CERTFILE = "test.crt"
RSAKEYFILE = "test.key"

##################
# Création à la volée d'un PDF #
##################

contents = ContentStream.new.setFilter(:FlateDecode)
contents.write OUTPUTFILE,
  :x => 350, :y => 750, :rendering => Text::Rendering::STROKE, :size => 30

puts "Now generating a new PDF file from scratch!"

pdf = PDF.new

page = Page.new
page.Contents = contents

pdf.append_page(page)

# Open certificate files
cert = OpenSSL::X509::Certificate.new(File.open(CERTFILE).read)
key = OpenSSL::PKey::RSA.new(File.open(RSAKEYFILE).read)

sigannot = Annotation::Widget::Signature.new.set_indirect(true)
sigannot.Rect = Rectangle[:llx => 89.0, :lly => 386.0, :urx => 190.0, :ury => 353.0]

page.add_annot(sigannot)
pdf.add_field(sigannot)

# Sign the PDF with the specified keys
pdf.sign(cert, key, [], sigannot, "France", "fred@security-labs.org", "Proof of Concept (owned)")

# Save the resulting file
pdf.save(OUTPUTFILE)

# Export a graph of the output document
pdf.export_to_graph('digsig.dot')
%x{dot -Tpng digsig.dot > digsig.png}

puts "PDF file saved as #{OUTPUTFILE}."
