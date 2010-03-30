require 'test/unit'

  class TC_PdfSig < Test::Unit::TestCase

    def setup
      @target = PDF.read("dataset/calc.pdf", :ignore_errors => false, :verbosity => Parser::VERBOSE_QUIET)
 
      @cert = OpenSSL::X509::Certificate.new(File.open("dataset/test.dummycrt").read)
      @key = OpenSSL::PKey::RSA.new(File.open("dataset/test.dummykey").read)
    end

    # def teardown
    # end

    def test_sig

      sigannot = Annotation::Widget::Signature.new.set_indirect(true)
      sigannot.Rect = Rectangle[:llx => 89.0, :lly => 386.0, :urx => 190.0, :ury => 353.0]

      assert_nothing_raised do
        @target.append_page(page = Page.new)
        page.add_annot(sigannot)

        @target.sign(@cert, @key, [], sigannot, "France", "fred@security-labs.org", "Proof of Concept (owned)")
      end

      assert @target.frozen?

      assert_nothing_raised do
        @target.saveas("/dev/null")
      end

    end

end
