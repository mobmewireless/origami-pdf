#!/usr/bin/env ruby 

begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../.."
  $: << ORIGAMIDIR
  require 'origami'
end
include Origami

if ARGV.size < 2
  puts "Usage: #{__FILE__} <signature> <files>"
end

SIG = ARGV.shift

ARGV.each do |file|
  pdf = PDF.read(file, :verbosity => Parser::VERBOSE_QUIET)
  colorprint "SIGNATURE '#{SIG}' MATCHED FOR '#{file}'\n", Colors::RED unless pdf.grep(SIG).empty?
end

