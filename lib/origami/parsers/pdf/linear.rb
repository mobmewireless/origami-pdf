=begin

= File
	parsers/linear.rb

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
require 'origami/pdf'

module Origami

  class PDF

    #
    # Create a new PDF linear Parser.
    #
    class LinearParser < Parser
      def parse(stream)
        super
        
        pdf = parse_initialize

        #
        # Parse each revision
        #
        revision = 0
        until @data.eos? do
          
          begin
            pdf.add_new_revision unless revision.zero?
            revision = revision + 1

            info "...Parsing revision #{pdf.revisions.size}..."
            loop do
              break if (object = parse_object).nil?
              pdf.insert(object)
            end

            pdf.revisions.last.xreftable = parse_xreftable

            trailer = parse_trailer
            pdf.revisions.last.trailer = trailer

            xrefstm = pdf.get_object_by_offset(trailer.startxref) || 
              (pdf.get_object_by_offset(trailer.XRefStm) if trailer.has_field? :XRefStm)

            if not xrefstm.nil?
              debug "Found a XRefStream for this revision at #{xrefstm.reference}"
              pdf.revisions.last.xrefstm = xrefstm
            end

          rescue SystemExit
            raise
          rescue Exception => e
            error "Cannot read : " + (@data.peek(10) + "...").inspect
            error "Stopped on exception : " + e.message

            break
          end

        end

        parse_finalize(pdf)
      end
    end
  end
end

