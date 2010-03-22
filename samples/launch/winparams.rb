#!/usr/bin/ruby 

$: << "../../parser"
require 'parser.rb'
include Origami

OUTPUTFILE = "#{File.basename(__FILE__, ".rb")}.pdf"

params = Action::WindowsApplication.new
params.F = "C:\\\\WINDOWS\\\\system32\\\\notepad.exe" # application or document to launch
params.D = "C:\\\\WINDOWS\\\\system32" # new current directory
params.P = "test.txt" # parameter to pass if F is an application

action = Action::Launch.new
action.Win = params

PDF.new.onDocumentOpen( action ).saveas(OUTPUTFILE)
