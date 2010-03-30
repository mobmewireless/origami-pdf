#!/usr/bin/env ruby 

require 'getopt.rb'

begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../.."
  $: << ORIGAMIDIR
  require 'origami'
end
include Origami

pdf, output_filename = get_params()

if ARGV.size < 1
  puts "Missing argument: <attachment>."
  exit
end

if not File.exist? ARGV[0]
  puts "Error: File does not exist '#{ARGV[0]}'. Exiting."
  exit
end

#
# Parses the PDF file.
#
filename = File.basename ARGV[0]

#
# Attachs it a embedded file.
#
attachment = pdf.attach_file(ARGV[0], :EmbeddedName => filename)
annot = Annotation::FileAttachment.new({:Name => Annotation::FileAttachment::Icons::PAPERCLIP, :FS => attachment})
annot.Contents = "This contains an embedded file called: '#{filename}'"
annot.Rect = [ 24, 600, 36, 616 ]

jscript = <<EOS
try
{
  this.exportDataObject({ cName: "#{filename}", nLaunch: 2 });
}
catch(e)
{
  app.alert({cMsg:"[line "+e.lineNumber+"] "+e.toString(), cTitle: e.name, nIcon: 0});
}
EOS
jsaction = Action::JavaScript.new(Stream.new(jscript))

#
# Add the annotation on the first page.
#
pdf.pages.first.add_annot(annot)

#
# Run the JavaScript when the first page is open.
#
pdf.pages.first.onOpen(jsaction)

# Save the modified document
pdf.saveas(output_filename)

puts "PDF file saved as #{output_filename}."

