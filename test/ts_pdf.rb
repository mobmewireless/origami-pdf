require 'test/unit/testsuite'
require 'tc_pdfparse.rb'
require 'tc_streams.rb'
require 'tc_pdfencrypt.rb'
require 'tc_pdfsig.rb'
require 'tc_pdfattach.rb'
require 'tc_pages.rb'
require 'tc_actions.rb'
require 'tc_annotations.rb'
require 'tc_pdfnew.rb'

begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../lib"
  $: << ORIGAMIDIR
  require 'origami'
end
include Origami

 class TS_PdfTests
   def self.suite
     suite = Test::Unit::TestSuite.new "PDF test suite"
     suite << TC_PdfParse.suite
     suite << TC_PdfNew.suite
     suite << TC_Streams.suite
     suite << TC_Pages.suite
     suite << TC_PdfEncrypt.suite
     suite << TC_PdfSig.suite
     suite << TC_PdfAttach.suite
     suite << TC_Actions.suite
     suite << TC_Annotations.suite
     suite
   end
 end
 
if ARGV.size > 0 and ARGV[0] == "gtk"
  require 'test/unit/ui/gtk2/testrunner'
  Test::Unit::UI::GTK2::TestRunner.run(TS_PdfTests)
else
  require 'test/unit/ui/console/testrunner'
  Test::Unit::UI::Console::TestRunner.run(TS_PdfTests)
end

exit 0
