#!/usr/bin/env ruby 

$: << "../../parser" << ".."
require 'getopt.rb'
require 'parser.rb'
include Origami

pdf, output_filename = get_params()

if ARGV.size < 1
  puts "Missing argument: <password>"
end

USERPASSWD = ARGV[0]
OWNERPASSWD = ARGV[0]

# Encrypts a document 
pdf.encrypt(USERPASSWD, OWNERPASSWD, :Algorithm => :AES)
pdf.saveas(output_filename)

puts "PDF file saved as #{output_filename}."
