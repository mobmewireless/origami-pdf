#!/usr/bin/env ruby

begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../../../lib"
  $: << ORIGAMIDIR
  require 'origami'
end
include Origami

pdf = PDF.read("sample.pdf", :verbosity => Parser::VERBOSE_DEBUG )

index = 1
pages = pdf.pages

pages.each do |page|
  page.onOpen(Action::GoTo.new(Destination::GlobalFit.new pages[index % pages.size].reference))

  index = index + 1
end

pdf.save("loopgoto_sample.pdf")

