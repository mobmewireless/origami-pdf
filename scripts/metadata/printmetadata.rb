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

pdf = PDF.read(ARGV[0], :verbosity => Parser::VERBOSE_INSANE)

colorprint("="*ARGV[0].length + "\n", Colors::BROWN)
colorprint(ARGV[0]+"\n", Colors::GREEN)
colorprint("="*ARGV[0].length+"\n", Colors::BROWN)

if pdf.has_document_info?
  puts "-------------------------------"
  puts "Document information dictionary"
  puts "-------------------------------"

  docinfo = pdf.get_document_info
  docinfo.each_pair do |name, item|
    puts "#{name.value}: #{item.value}"
  end
else
  colorprint("No document information dictionary found.\n", Colors::RED)
end

puts

if pdf.has_metadata?
  puts "---------------"
  puts "Metadata stream"
  puts "---------------"

  metadata = pdf.get_metadata
  metadata.each_pair do |name, item|
    puts "#{name}: #{item}"
  end
else
  colorprint("No metadata stream found.\n", Colors::RED)
end
