#!/usr/bin/env ruby 

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

#
# Extract its pages.
#
pageset = pdf.pages

#
# Add a NextPage action at the opening of each page...
#
index = 0
pageset.each { |page| 
  puts "Corrupting page #{index}"
  page.onOpen(Action::Named.new(Action::Named::NEXTPAGE))
  index += 1
}

#
# ...except for the last page, where we jump back to first one.
#
puts "Corrupting last page"
pageset.last.onOpen(Action::Named.new(Action::Named::FIRSTPAGE))
  
pdf.saveas(output_filename)

puts "Infected copy saved as #{output_filename}."
