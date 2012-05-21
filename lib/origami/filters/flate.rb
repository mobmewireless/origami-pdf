=begin

= File
	filters/flate.rb

= Info
	This file is part of Origami, PDF manipulation framework for Ruby
	Copyright (C) 2010	Guillaume Delugré <guillaume@security-labs.org>
	All right reserved.
	
  Origami is free software: you can redistribute it and/or modify
  it under the terms of the GNU Lesser General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Origami is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License
  along with Origami.  If not, see <http://www.gnu.org/licenses/>.

=end

require 'zlib'
require 'origami/filters/predictors'

module Origami
  
  module Filter

    class InvalidFlateDataError < InvalidFilterDataError; end #:nodoc:
    
    #
    # Class representing a Filter used to encode and decode data with zlib/Flate compression algorithm.
    #
    class Flate
      include Filter
      
      EOD = 257 #:nodoc:
 
      class DecodeParms < Dictionary
        include StandardObject

        field   :Predictor,         :Type => Integer, :Default => 1
        field   :Colors,            :Type => Integer, :Default => 1
        field   :BitsPerComponent,  :Type => Integer, :Default => 8
        field   :Columns,           :Type => Integer, :Default => 1
      end
      
      #
      # Create a new Flate Filter.
      # _parameters_:: A hash of filter options (ignored).
      #
      def initialize(parameters = {})
        super(DecodeParms.new(parameters))
      end
      
      #
      # Encodes data using zlib/Deflate compression method.
      # _stream_:: The data to encode.
      #
      def encode(stream)
        if @params.Predictor.is_a?(Integer)
          colors  = @params.Colors.is_a?(Integer) ? @params.Colors.to_i : 1
          bpc     = @params.BitsPerComponent.is_a?(Integer) ? @params.BitsPerComponent.to_i : 8
          columns = @params.Columns.is_a?(Integer) ? @params.Columns.to_i : 1

          stream = Predictor.do_pre_prediction(stream, @params.Predictor.to_i, colors, bpc, columns)
        end       
        
        Zlib::Deflate.deflate(stream, Zlib::BEST_COMPRESSION)
      end
      
      #
      # Decodes data using zlib/Inflate decompression method.
      # _stream_:: The data to decode.
      #
      def decode(stream)
        
        zlib_stream = Zlib::Inflate.new
        begin
          uncompressed = zlib_stream.inflate(stream)
        rescue Zlib::DataError => zlib_except
          raise InvalidFlateDataError.new(zlib_except.message, zlib_stream.flush_next_out)
        end

        if @params.Predictor.is_a?(Integer)
          colors  = @params.Colors.is_a?(Integer) ? @params.Colors.to_i : 1
          bpc     = @params.BitsPerComponent.is_a?(Integer) ? @params.BitsPerComponent.to_i : 8
          columns = @params.Columns.is_a?(Integer) ? @params.Columns.to_i : 1

          uncompressed = Predictor.do_post_prediction(uncompressed, @params.Predictor.to_i, colors, bpc, columns)
        end

        uncompressed
      end

    end
  end
end

