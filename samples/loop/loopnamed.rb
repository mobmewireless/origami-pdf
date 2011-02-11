#!/usr/bin/env ruby

begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../.."
  $: << ORIGAMIDIR
  require 'origami'
end
include Origami

pdf = PDF.read("sample.pdf", :verbosity => Parser::VERBOSE_DEBUG )

  pages = pdf.pages
  pages.each { |page| 
    page.onOpen(Action::Named.new(Action::Named::NEXTPAGE))
  }
  
  pages.last.onOpen(Action::Named.new(Action::Named::FIRSTPAGE))
  
  infected_name = "loopnamed_" + pdf.filename
  
  pdf.save(infected_name)
  
  puts "Infected copy saved as #{infected_name}."
