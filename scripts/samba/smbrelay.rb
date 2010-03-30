#!/usr/bin/ruby 
# -*- coding: iso-8859-1 -*-


#
# FIXME: 
#   Assumes there is no AA on the 1st page.
#   If there is, it is replaced by our own.
# 

$: << ".."
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

dst = ExternalFile.new("\\\\#{ARGV[0]}\\origami\\owned.pdf")
gotor = Action::GoToR.new(dst, Destination::GlobalFit.new(0), true)
pdf.pages.first.onOpen(gotor)

pdf.saveas(output_filename)
puts "PDF file saved as #{output_filename}."

