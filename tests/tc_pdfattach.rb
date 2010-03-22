require 'test/unit'

  class TC_PdfAttach < Test::Unit::TestCase
    def setup
      @target = PDF.new
      @attachment = "dataset/test.dummycrt"
    end

    # def teardown
    # end

    def test_attachfile
      assert_nothing_raised do
        fspec = @target.attach_file(@attachment, :EmbeddedName => "foo.bar")
      end

      assert_nothing_raised do
        @target.saveas("/dev/null")
      end
    end

end
