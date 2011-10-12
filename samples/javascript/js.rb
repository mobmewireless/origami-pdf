#!/usr/bin/env ruby 

begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../../lib"
  $: << ORIGAMIDIR
  require 'origami'
end
include Origami

if defined?(PDF::JavaScript::Engine)

  INPUTFILE = "attached.txt"

  # Creating a new file
  pdf = PDF.new

  # Embedding the file into the PDF.
  pdf.attach_file(INPUTFILE, 
    :EmbeddedName => "README.txt", 
    :Filter => :ASCIIHexDecode
  )

  # Example of JS payload
  js = <<-JS
    if ( app.viewerVersion == 8 )
      eval("this.exportDataObject({cName:'README.txt', nLaunch:2});");
    this.closeDoc();
  JS
  pdf.onDocumentOpen Action::JavaScript.new(js)

  # Tweaking the engine options
  pdf.js_engine.options[:log_method_calls] = true
  pdf.js_engine.options[:viewerVersion] = 8

  # Hooking eval()
  pdf.js_engine.hook 'eval' do |eval, expr|
    puts "Hook: eval(#{expr.inspect})"
    eval.call(expr) # calling the real eval method
  end

  # Example of inline JS evaluation
  pdf.eval_js 'console.println(util.stringFromStream(this.getDataObjectContents("README.txt")))'

  # Executes the string as a JS script
  pdf.Catalog.OpenAction[:JS].eval_js

else
  puts "JavaScript support not found. You need to install therubyracer gem."
end

