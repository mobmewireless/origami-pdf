require 'test/unit'
require 'stringio'

  class TC_Streams < Test::Unit::TestCase
    def setup
      @target = PDF.new
      @output = StringIO.new
      @data = "0123456789" * 1024
    end

    # def teardown
    # end
    
    def test_predictors

      stm = Stream.new(@data, :Filter => :FlateDecode)
      stm.set_predictor(Filter::Predictor::TIFF)
      raw = stm.rawdata
      stm.data = nil
      stm.rawdata = raw

      assert_equal @data, stm.data

      stm = Stream.new(@data, :Filter => :FlateDecode)
      stm.set_predictor(Filter::Predictor::PNG_SUB)
      raw = stm.rawdata
      stm.data = nil
      stm.rawdata = raw

      assert_equal @data, stm.data

      stm = Stream.new(@data, :Filter => :FlateDecode)
      stm.set_predictor(Filter::Predictor::PNG_UP)
      raw = stm.rawdata
      stm.data = nil
      stm.rawdata = raw

      assert_equal stm.data, @data

      stm = Stream.new(@data, :Filter => :FlateDecode)
      stm.set_predictor(Filter::Predictor::PNG_AVERAGE)
      raw = stm.rawdata
      stm.data = nil
      stm.rawdata = raw

      assert_equal stm.data, @data

      stm = Stream.new(@data, :Filter => :FlateDecode)
      stm.set_predictor(Filter::Predictor::PNG_PAETH)
      raw = stm.rawdata
      stm.data = nil
      stm.rawdata = raw

      assert_equal stm.data, @data

   end
   
    def test_filter_flate

      stm = Stream.new(@data, :Filter => :FlateDecode)
      raw = stm.rawdata
      stm.data = nil
      stm.rawdata = raw

      assert_equal stm.data, @data
    end

    def test_filter_asciihex

      stm = Stream.new(@data, :Filter => :ASCIIHexDecode)
      raw = stm.rawdata
      stm.data = nil
      stm.rawdata = raw

      assert_equal stm.data, @data
    end

    def test_filter_ascii85

      stm = Stream.new(@data, :Filter => :ASCII85Decode)
      raw = stm.rawdata
      stm.data = nil
      stm.rawdata = raw

      assert_equal stm.data, @data
    end

    def test_filter_rle

      stm = Stream.new(@data, :Filter => :RunLengthDecode)
      raw = stm.rawdata
      stm.data = nil
      stm.rawdata = raw

      assert_equal stm.data, @data
    end

    def test_filter_lzw

      stm = Stream.new(@data, :Filter => :LZWDecode)
      raw = stm.rawdata
      stm.data = nil
      stm.rawdata = raw

      assert_equal stm.data, @data
    end

    def test_filter_ccittfax
      
      stm = Stream.new(@data[0, 216], :Filter => :CCITTFaxDecode)
      
      raw = stm.rawdata
      stm.data = nil
      stm.rawdata = raw

      assert_equal stm.data, @data[0, 216]
    end

    def test_stream
      stm = Stream.new(@data, :Filter => :ASCIIHexDecode )
      @target << stm

      stm.pre_build
      assert stm.Length == stm.rawdata.length

      @target.save(@output)
    end

end
