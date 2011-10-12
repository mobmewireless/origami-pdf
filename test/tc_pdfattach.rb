require 'test/unit'
require 'stringio'

  class TC_PdfAttach < Test::Unit::TestCase
    def setup
      @target = PDF.new
      @attachment = "test/dataset/test.dummycrt"
      @output = StringIO.new
    end

    # def teardown
    # end

    def test_attachfile
      assert_nothing_raised do
        fspec = @target.attach_file(@attachment, :EmbeddedName => "foo.bar")
      end

      assert_nothing_raised do
        @target.save(@output)
      end
    end

end
