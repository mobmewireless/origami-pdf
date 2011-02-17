#!/usr/bin/env ruby

begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../.."
  $: << ORIGAMIDIR
  require 'origami'
end
include Origami

if ARGV.size < 1
  puts "Usage: #{$0} <filename>"
  exit
end

pdf = PDF.read(ARGV[0], :verbosity => Parser::VERBOSE_QUIET)

if pdf.has_document_info?
  colorprint "[*] Document information dictionary:\n", Colors::MAGENTA

  docinfo = pdf.get_document_info
  docinfo.each_pair do |name, item|
    puts "#{colorize(name.value.to_s.ljust(20,' '), Colors::GREEN)}: #{item.solve.value}"
  end
else
  colorprint("No document information dictionary found.\n", Colors::RED)
end

puts

if pdf.has_metadata?
  colorprint "[*] Metadata stream:\n", Colors::MAGENTA

  metadata = pdf.get_metadata
  metadata.each_pair do |name, item|
    puts "#{colorize(name.ljust(20,' '), Colors::GREEN)}: #{item}"
  end
else
  colorprint("No metadata stream found.\n", Colors::RED)
end

