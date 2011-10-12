require 'test/unit'
require 'stringio'

  class TC_PdfEncrypt < Test::Unit::TestCase
    def setup
      @target = PDF.read("test/dataset/calc.pdf", :ignore_errors => false, :verbosity => Parser::VERBOSE_QUIET)
      @output = StringIO.new
    end

    # def teardown
    # end

    def test_encrypt_rc4_40b
      @output.string = ""
      assert_nothing_raised do
        @target.encrypt(:cipher => 'rc4', :key_size => 40).save(@output);
      end
    end

    def test_encrypt_rc4_128b
      @output.string = ""
      assert_nothing_raised do
        @target.encrypt(:cipher => 'rc4').save(@output);
      end
    end

    def test_encrypt_aes_128b
      @output.string = ""
      assert_nothing_raised do
        @target.encrypt(:cipher => 'aes').save(@output);
      end
    end

    def test_decrypt_rc4_40b
      pdf = nil
      @output.string = ""
      assert_nothing_raised do
        pdf = PDF.new.encrypt(:cipher => 'rc4', :key_size => 40)
        pdf.Catalog[:Test] = "test"
        pdf.save(@output)
      end

      assert_not_equal pdf.Catalog[:Test], "test"

      assert_nothing_raised do
        @output = @output.reopen(@output.string, "r")
        pdf = PDF.read(@output, :ignore_errors => false, :verbosity => Parser::VERBOSE_QUIET)
      end

      assert_equal pdf.Catalog[:Test], "test"
    end

    def test_decrypt_rc4_128b
      pdf = nil
      @output.string = ""
      assert_nothing_raised do
        pdf = PDF.new.encrypt(:cipher => 'rc4')
        pdf.Catalog[:Test] = "test"
        pdf.save(@output)
      end

      assert_not_equal pdf.Catalog[:Test], "test"

      assert_nothing_raised do
        @output.reopen(@output.string, "r")
        pdf = PDF.read(@output, :ignore_errors => false, :verbosity => Parser::VERBOSE_QUIET)
      end

      assert_equal pdf.Catalog[:Test], "test"
    end

    def test_decrypt_aes_128b
      pdf = nil
      @output.string = ""
      assert_nothing_raised do
        pdf = PDF.new.encrypt(:cipher => 'aes')
        pdf.Catalog[:Test] = "test"
        pdf.save(@output)
      end

      assert_not_equal pdf.Catalog[:Test], "test"

      assert_nothing_raised do
        @output = @output.reopen(@output.string, "r")
        pdf = PDF.read(@output, :ignore_errors => false, :verbosity => Parser::VERBOSE_QUIET)
      end

      assert_equal pdf.Catalog[:Test], "test"
    end

    def test_decrypt_aes_256b
      pdf = nil
      @output.string = ""
      assert_nothing_raised do
        pdf = PDF.new.encrypt(:cipher => 'aes', :key_size => 256)
        pdf.Catalog[:Test] = "test"
        pdf.save(@output)
      end

      assert_not_equal pdf.Catalog[:Test], "test"

      assert_nothing_raised do
        @output = @output.reopen(@output.string, "r")
        pdf = PDF.read(@output, :ignore_errors => false, :verbosity => Parser::VERBOSE_QUIET)
      end

      assert_equal pdf.Catalog[:Test], "test"
    end

end
