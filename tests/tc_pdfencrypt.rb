require 'test/unit'

  class TC_PdfEncrypt < Test::Unit::TestCase
    def setup
      @target = PDF.read("dataset/calc.pdf", :ignore_errors => false, :verbosity => Parser::VERBOSE_QUIET)
    end

    # def teardown
    # end

    def test_encrypt_rc4_40b
      assert_nothing_raised do
        @target.encrypt("", "", :Algorithm => :RC4, :KeyLength => 40).saveas("/dev/null");
      end
    end

    def test_encrypt_rc4_128b
      assert_nothing_raised do
        @target.encrypt("","", :Algorithm => :RC4).saveas("/dev/null");
      end
    end

    def test_encrypt_aes_128b
      assert_nothing_raised do
        @target.encrypt("","", :Algorithm => :AES).saveas("/dev/null");
      end
    end

    def test_decrypt_rc4_40b
      pdf = nil
      assert_nothing_raised do
        pdf = PDF.new.encrypt("","", :Algorithm => :RC4, :KeyLength => 40)
        pdf.Catalog[:Test] = "test"
        pdf.saveas("/tmp/rc4_40.pdf")
      end

      assert_not_equal pdf.Catalog[:Test], "test"

      assert_nothing_raised do
        pdf = PDF.read("/tmp/rc4_40.pdf", :ignore_errors => false, :verbosity => Parser::VERBOSE_QUIET)
      end

      assert_equal pdf.Catalog[:Test], "test"
    end

    def test_decrypt_rc4_128b
      pdf = nil
      assert_nothing_raised do
        pdf = PDF.new.encrypt("","", :Algorithm => :RC4)
        pdf.Catalog[:Test] = "test"
        pdf.saveas("/tmp/rc4_128.pdf")
      end

      assert_not_equal pdf.Catalog[:Test], "test"

      assert_nothing_raised do
        pdf = PDF.read("/tmp/rc4_128.pdf", :ignore_errors => false, :verbosity => Parser::VERBOSE_QUIET)
      end

      assert_equal pdf.Catalog[:Test], "test"
    end

    def test_decrypt_aes_128b
      pdf = nil
      assert_nothing_raised do
        pdf = PDF.new.encrypt("","", :Algorithm => :AES)
        pdf.Catalog[:Test] = "test"
        pdf.saveas("/tmp/aes_128.pdf")
      end

      assert_not_equal pdf.Catalog[:Test], "test"

      assert_nothing_raised do
        pdf = PDF.read("/tmp/aes_128.pdf", :ignore_errors => false, :verbosity => Parser::VERBOSE_QUIET)
      end

      assert_equal pdf.Catalog[:Test], "test"
    end

end
