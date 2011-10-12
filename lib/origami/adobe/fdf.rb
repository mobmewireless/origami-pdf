=begin

= File
	adobe/fdf.rb

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

require 'origami/object'
require 'origami/name'
require 'origami/dictionary'
require 'origami/reference'
require 'origami/boolean'
require 'origami/numeric'
require 'origami/string'
require 'origami/array'
require 'origami/trailer'
require 'origami/xreftable'

module Origami

  module Adobe
    
    #
    # Class representing an AcroForm Forms Data Format file.
    #
    class FDF
      
      class Header

        MAGIC = /\A%FDF-(\d)\.(\d)/
        
        attr_accessor :majorversion, :minorversion
        
        #
        # Creates a file header, with the given major and minor versions.
        # _majorversion_:: Major version.
        # _minorversion_:: Minor version.
        #
        def initialize(majorversion = 2, minorversion = 1)
          @majorversion, @minorversion = majorversion, minorversion
        end
        
        def self.parse(stream) #:nodoc:
          
          if not stream.scan(MAGIC).nil?
            maj = stream[1].to_i
            min = stream[2].to_i
          else
            raise InvalidHeader, "Invalid header format"
          end
          
          PPKLite::Header.new(maj,min)
        end
        
        def to_s
          "%FDF-#{@majorversion}.#{@minorversion}" + EOL
        end
        
        def to_sym #:nodoc:
          "#{@majorversion}.#{@minorversion}".to_sym
        end
        
        def to_f #:nodoc:
          to_sym.to_s.to_f
        end
      
      end

      class Revision #:nodoc;
        attr_accessor :pdf
        attr_accessor :body, :xreftable, :trailer
        
        def initialize(adbk)
          @pdf = adbk
          @body = {}
          @xreftable = nil
          @trailer = nil
        end

        def trailer=(trl)
          trl.pdf = @pdf
          @trailer = trl
        end
      end

      attr_accessor :header, :revisions
      
      def initialize #:nodoc:
        @header = FDF::Header.new
        @revisions = [ Revision.new(self) ]
        @revisions.first.trailer = Trailer.new
      end
      
      def objects
        def append_subobj(root, objset)
          if objset.find{ |o| o.object_id == root.object_id }.nil?
            objset << root
            if root.is_a?(Array) or root.is_a?(Dictionary)
              root.each { |subobj| append_subobj(subobj, objset) unless subobj.is_a?(Reference) }
            end
          end
        end
        
        objset = []
        @revisions.first.body.values.each do |object|
          unless object.is_a?(Reference)
            append_subobj(object, objset)
          end
        end
        
        objset
      end
      
      def <<(object)
        
        object.set_indirect(true)
        
        if object.no.zero?
        maxno = 1
          while get_object(maxno) do maxno = maxno.succ end
          
          object.generation = 0
          object.no = maxno
        end
        
        @revisions.first.body[object.reference] = object
        
        object.reference
      end
      
      def Catalog
        get_object(@trailer.Root)
      end
      
      def save(filename)
        
        bin = ""
        bin << @header.to_s

        lastno, brange = 0, 0
          
        xrefs = [ XRef.new(0, XRef::LASTFREE, XRef::FREE) ]
        xrefsection = XRef::Section.new
 
        @revisions.first.body.values.sort.each { |obj|
          if (obj.no - lastno).abs > 1
            xrefsection << XRef::Subsection.new(brange, xrefs)
            brange = obj.no
            xrefs.clear
          end
          
          xrefs << XRef.new(bin.size, obj.generation, XRef::USED)
          lastno = obj.no

          bin << obj.to_s
        }
        
        xrefsection << XRef::Subsection.new(brange, xrefs)
        
        @xreftable = xrefsection
        @trailer ||= Trailer.new
        @trailer.Size = rev.body.size + 1
        @trailer.startxref = bin.size

        bin << @xreftable.to_s
        bin << @trailer.to_s

        fd = File.open(filename, "w").binmode
          fd << bin 
        fd.close
        
        show_entries
      end
      alias saveas save
      
      private
      
      def rebuildxrefs #:nodoc:
        
        startxref = @header.to_s.size
        
        @revisions.first.body.values.each { |object|
          startxref += object.to_s.size
        }
          
        @xreftable = buildxrefs(@revisions.first.body)
        
        @trailer ||= Trailer.new
        @trailer.Size = @revisions.first.body.size + 1
        @trailer.startxref = startxref
        
        self
      end
      
      def buildxrefs(objects) #:nodoc:
        
        lastno = 0
        brange = 0
        
        xrefs = [ XRef.new(0, XRef::LASTFREE, XRef::FREE) ]
        
        xrefsection = XRef::Section.new
        objects.sort.each { |object|
          if (object.no - lastno).abs > 1
            xrefsection << XRef::Subsection.new(brange, xrefs)
            brange = object.no
            xrefs.clear
          end
          
          xrefs << XRef.new(get_object_offset(object.no, object.generation), object.generation, XRef::USED)

          lastno = object.no
        }
        
        xrefsection << XRef::Subsection.new(brange, xrefs)
        
        xrefsection
      end
     
      def get_object_offset(no,generation) #:nodoc:

        bodyoffset = @header.to_s.size
        
        objectoffset = bodyoffset
          
        @revisions.first.body.values.each { |object|
          if object.no == no and object.generation == generation then return objectoffset
          else
            objectoffset += object.to_s.size
          end
        }
        
        nil
      end
      
    end
    
  end
  
end

