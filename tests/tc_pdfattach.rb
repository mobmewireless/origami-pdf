require 'test/unit'
require 'stringio'

  class TC_PdfAttach < Test::Unit::TestCase
    def setup
      @target = PDF.new
      @attachment = "tests/dataset/test.dummycrt"
      @output = StringIO.new
    end

    # def teardown
    # end

    def test_attachfile
      assert_nothing_raised do
        fspec = @target.attach_file(@attachment, :EmbeddedName => "foo.bar")
      end

      assert_nothing_raised do
        @target.saveas(@output)
      end
    end

end
