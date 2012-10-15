#!/usr/bin/ruby 


begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../../lib"
  $: << ORIGAMIDIR
  require 'origami'
end
include Origami



mypdf = Origami::PDF.read "./sample.pdf"








hash_to_be_signed = mypdf.prepare_for_sign(   
  

  :location => "India", 
  :contact => "sajith@mobme.in", 
  :reason => "Proof of Concept Sajith Vishnu" 


)


p hash_to_be_signed



mypdf.save('prepared.pdf')