#!/usr/bin/ruby 

begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../../../lib"
  $: << ORIGAMIDIR
  require 'origami'
end
include Origami

OUTPUTFILE = "#{File.basename(__FILE__, ".rb")}.pdf"

params = Action::Launch::WindowsLaunchParams.new
params.F = "C:\\\\WINDOWS\\\\system32\\\\notepad.exe" # application or document to launch
params.D = "C:\\\\WINDOWS\\\\system32" # new current directory
params.P = "test.txt" # parameter to pass if F is an application

action = Action::Launch.new
action.Win = params

PDF.new.onDocumentOpen( action ).save(OUTPUTFILE)
