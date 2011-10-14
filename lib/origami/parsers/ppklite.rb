=begin

= File
	parsers/ppklite.rb

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

module Origami

  module Adobe

    class PPKLite

      class Parser < Origami::Parser
        def parse(stream) #:nodoc:
          super

          addrbk = Adobe::PPKLite.new
          addrbk.header = Adobe::PPKLite::Header.parse(stream)
          @options[:callback].call(addrbk.header)
          
          loop do
            break if (object = parse_object).nil?
            addrbk << object
          end

          addrbk.revisions.first.xreftable = parse_xreftable
          addrbm.revisions.first.trailer = parse_trailer
          book_specialize_entries(addrbk)

          addrbk
        end
        
        def book_specialize_entries(addrbk) #:nodoc:
          addrbk.revisions.first.body.each_pair do |ref, obj|
            
            if obj.is_a?(Dictionary)
              
              if obj[:Type] == :Catalog
                
                o = Adobe::PPKLite::Catalog.new(obj)
                o.generation, o.no, o.file_offset = obj.generation, obj.no, obj.file_offset
                
                if o.PPK.is_a?(Dictionary) and o.PPK[:Type] == :PPK
                  o.PPK = Adobe::PPKLite::PPK.new(o.PPK)
                  
                  if o.PPK.User.is_a?(Dictionary) and o.PPK.User[:Type] == :User
                    o.PPK.User = Adobe::PPKLite::UserList.new(o.PPK.User)
                  end
                  
                  if o.PPK.AddressBook.is_a?(Dictionary) and o.PPK.AddressBook[:Type] == :AddressBook
                    o.PPK.AddressBook = Adobe::PPKLite::AddressList.new(o.PPK.AddressBook)
                  end
                end
                
                addrbk.revisions.first.body[ref] = o
                
              elsif obj[:ABEType] == Adobe::PPKLite::Descriptor::USER
                o = Adobe::PPKLite::User.new(obj)
                o.generation, o.no, o.file_offset = obj.generation, obj.no, obj.file_offset
                
                addrbk.revisions.first.body[ref] = o
              elsif obj[:ABEType] == Adobe::PPKLite::Descriptor::CERTIFICATE
                o = Adobe::PPKLite::Certificate.new(obj)
                o.generation, o.no, o.file_offset = obj.generation, obj.no, obj.file_offset
                
                addrbk.revisions.first.body[ref] = o
              end

            end
          end
        end
      end
    end
  end
end

