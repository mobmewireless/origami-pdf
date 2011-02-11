#!/usr/bin/env ruby 

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

if ARGV.size < 1
  puts "Missing argument: <password>"
end

USERPASSWD = ARGV[0]
OWNERPASSWD = ARGV[0]

# Encrypts a document 
pdf.encrypt(USERPASSWD, OWNERPASSWD, :Algorithm => :AES)
pdf.save(output_filename)

puts "PDF file saved as #{output_filename}."
