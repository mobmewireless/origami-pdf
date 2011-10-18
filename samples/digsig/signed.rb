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

contents = ContentStream.new.setFilter(:FlateDecode)
contents.write OUTPUTFILE,
  :x => 350, :y => 750, :rendering => Text::Rendering::STROKE, :size => 30

pdf = PDF.new
page = Page.new.setContents(contents)
pdf.append_page(page)

# Open certificate files
cert = OpenSSL::X509::Certificate.new(File.open(CERTFILE).read)
key = OpenSSL::PKey::RSA.new(File.open(RSAKEYFILE).read)

sigannot = Annotation::Widget::Signature.new
sigannot.Rect = Rectangle[:llx => 89.0, :lly => 386.0, :urx => 190.0, :ury => 353.0]

page.add_annot(sigannot)

# Sign the PDF with the specified keys
pdf.sign(cert, key, 
  :method => 'adbe.pkcs7.sha1',
  :annotation => sigannot, 
  :location => "France", 
  :contact => "fred@security-labs.org", 
  :reason => "Proof of Concept"
)

# Save the resulting file
pdf.save(OUTPUTFILE)

