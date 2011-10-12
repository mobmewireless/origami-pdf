=begin

= File
	parsers/fdf.rb

= Info
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

require 'origami/parser'
require 'origami/adobe/fdf'

module Origami

  class Adobe::FDF
    class Parser < Origami::Parser
      def parse(stream) #:nodoc:
        super

        fdf = Adobe::FDF.new
        fdf.header = Adobe::FDF::Header.parse(stream)
        @options[:callback].call(fdf.header)
        
        parse_objects(fdf)
        parse_xreftable(fdf)
        parse_trailer(fdf)

        addrbk
      end
    end
  end
end

