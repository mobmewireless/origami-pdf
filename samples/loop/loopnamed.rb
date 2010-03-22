#!/usr/bin/env ruby

$: << "../../parser"
require 'parser.rb'
include Origami

pdf = PDF.read("sample.pdf", :verbosity => Parser::VERBOSE_DEBUG )

  pages = pdf.pages
  pages.each { |page| 
    page.onOpen(Action::Named.new(Action::Named::NEXTPAGE))
  }
  
  pages.last.onOpen(Action::Named.new(Action::Named::FIRSTPAGE))
  
  infected_name = "loopnamed_" + pdf.filename
  
  pdf.saveas(infected_name)
  
  puts "Infected copy saved as #{infected_name}."
