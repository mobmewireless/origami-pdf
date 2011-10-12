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

pages = pdf.pages

pages.each do |page| 
  page.onOpen(Action::Named.new(Action::Named::NEXTPAGE)) unless page == pages.last
end
pages.last.onOpen(Action::Named.new(Action::Named::FIRSTPAGE))

pdf.save("loopnamed_sample.pdf")
