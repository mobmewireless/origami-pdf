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
    class LinearParser < Origami::Parser
      def parse(stream)
        super
        
        if @options[:force] == true
          @data.skip_until(/%PDF-/).nil?
          @data.pos = @data.pos - 5
        end

        pdf = PDF.new(false)

        info "...Reading header..."
        begin
          pdf.header = PDF::Header.parse(@data)
          @options[:callback].call(pdf.header)
        rescue InvalidHeaderError => e
          if @options[:ignore_errors] == true
            warn "PDF header is invalid, ignoring..."
          else
            raise e
          end
        end
        
        #
        # Parse each revision
        #
        revision = 0
        until @data.eos? do
          
          begin
            
            pdf.add_new_revision unless revision.zero?
            revision = revision.succ
            
            info "...Parsing revision #{pdf.revisions.size}..."
            parse_objects(pdf)
            parse_xreftable(pdf)
            parse_trailer(pdf)
            
          rescue SystemExit
            raise
          rescue Exception => e
            error "Cannot read : " + (@data.peek(10) + "...").inspect
            error "Stopped on exception : " + e.message
            
            break
          end
          
        end

        warn "This file has been linearized." if pdf.is_linearized?

        #
        # Decrypt encrypted file contents
        #
        if pdf.is_encrypted?
          warn "This document contains encrypted data!"
        
          passwd = @options[:password]
          begin
            pdf.decrypt(passwd)
          rescue EncryptionInvalidPasswordError
            if passwd.empty?
              passwd = @options[:prompt_password].call
              retry unless passwd.empty?
            end

            raise EncryptionInvalidPasswordError
          end
        end

        if pdf.is_signed?
          warn "This document has been signed!"
        end

        pdf
      end
    end
  end
end

