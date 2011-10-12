require 'test/unit'

  class TC_PdfParse < Test::Unit::TestCase
    def setup
      @data = 
        %w{ 
          test/dataset/empty.pdf
          test/dataset/calc.pdf 
          test/dataset/crypto.pdf
          }

      @dict = StringScanner.new "<</N 2 0 R/x1 null/Pi 3.14 /a <<>>>>"

      @bytestring = StringScanner.new "(\\122\\125by\\n)"
      @hexastring = StringScanner.new "<52  55  62 79 0A>"
      @true = StringScanner.new "true"
      @false = StringScanner.new "false"
      @real = StringScanner.new "-3.141592653"
      @int = StringScanner.new "00000000002000000000000"
      @name = StringScanner.new "/#52#55#62#79#0A"
    end

    # def teardown
    # end

    def test_parsepdf
      @data.each { |file|
        assert_nothing_raised do
          PDF.read(file, :ignore_errors => false, :verbosity => Parser::VERBOSE_QUIET)
        end
      }
    end

    def test_parsedictionary

      dict = nil
      assert_nothing_raised do
        dict = Dictionary.parse(@dict)
      end

      assert dict[:Pi] == 3.14
      assert dict[:a].is_a?(Dictionary)

    end

    def test_parsestring
      str = nil
      assert_nothing_raised do
        str = ByteString.parse(@bytestring)
      end

      assert str.value == "RUby\n"

      assert_nothing_raised do
        str = HexaString.parse(@hexastring)
      end

      assert str.value == "RUby\n"
    end

    def test_parsebool
      _true, _false = nil
      assert_nothing_raised do
        _true = Boolean.parse(@true)
        _false = Boolean.parse(@false)
      end

      assert _false.false?
      assert (not _true.false?)
    end

    def test_parsereal
      real = nil
      assert_nothing_raised do
        real = Real.parse(@real)
      end

      assert_equal real, -3.141592653
    end

    def test_parseint
      int = nil
      assert_nothing_raised do
        int = Origami::Integer.parse(@int)
      end

      assert_equal int, 2000000000000
    end

    def test_parsename
      name = nil
      assert_nothing_raised do
        name = Name.parse(@name)
      end

      assert_equal name.value, :"RUby\n"
    end
end
