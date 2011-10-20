=begin

= File
	pdf.rb

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

require 'origami/object'
require 'origami/null'
require 'origami/name'
require 'origami/dictionary'
require 'origami/reference'
require 'origami/boolean'
require 'origami/numeric'
require 'origami/string'
require 'origami/array'
require 'origami/stream'
require 'origami/filters'
require 'origami/trailer'
require 'origami/xreftable'
require 'origami/header'
require 'origami/functions'
require 'origami/catalog'
require 'origami/font'
require 'origami/page'
require 'origami/graphics'
require 'origami/destinations'
require 'origami/outline'
require 'origami/actions'
require 'origami/file'
require 'origami/acroform'
require 'origami/annotations'
require 'origami/3d'
require 'origami/signature'
require 'origami/webcapture'
require 'origami/metadata'
require 'origami/export'
require 'origami/webcapture'
require 'origami/encryption'
require 'origami/linearization'
require 'origami/obfuscation'
require 'origami/xfa'
require 'origami/javascript'
require 'origami/outputintents'

require 'origami/parsers/pdf'

module Origami

  VERSION   = "1.2.2"
  REVISION  = "$Revision$" #:nodoc:
  
  #
  # Global options for Origami.
  #
  OPTIONS   = 
  {
    :enable_type_checking => true,  # set to false to disable type consistency checks during compilation.
    :enable_type_guessing => true,  # set to false to prevent the parser to guess the type of special dictionary and streams (not recommended).
    :use_openssl => true            # set to false to use Origami crypto backend.
  }
  
  begin
    require 'openssl'
    OPTIONS[:use_openssl] = true
  rescue LoadError
    OPTIONS[:use_openssl] = false
  end

  DICT_SPECIAL_TYPES = #:nodoc:
  { 
    :Catalog => Catalog, 
    :Pages => PageTreeNode, 
    :Page => Page, 
    :Filespec => FileSpec, 
    :Action => Action,
    :Font => Font,
    :FontDescriptor => FontDescriptor,
    :Encoding => Encoding,
    :Annot => Annotation,
    :Border => Annotation::BorderStyle,
    :Outlines => Outline,
    :OutputIntent => OutputIntent,
    :Sig => Signature::DigitalSignature,
    :SigRef => Signature::Reference,
    :SigFieldLock => Field::SignatureLock,
    :SV => Field::SignatureSeedValue,
    :SVCert => Field::CertificateSeedValue,
    :ExtGState => Graphics::ExtGState,
    :RichMediaSettings => Annotation::RichMedia::Settings,
    :RichMediaActivation => Annotation::RichMedia::Activation,
    :RichMediaDeactivation => Annotation::RichMedia::Deactivation,
    :RichMediaAnimation => Annotation::RichMedia::Animation,
    :RichMediaPresentation => Annotation::RichMedia::Presentation,
    :RichMediaWindow => Annotation::RichMedia::Window,
    :RichMediaPosition => Annotation::RichMedia::Position,
    :RichMediaContent => Annotation::RichMedia::Content,
    :RichMediaConfiguration => Annotation::RichMedia::Configuration,
    :RichMediaInstance => Annotation::RichMedia::Instance,
    :RichMediaParams => Annotation::RichMedia::Parameters,
    :CuePoint => Annotation::RichMedia::CuePoint
  }
  
  STM_SPECIAL_TYPES = #:nodoc:
  {
    :ObjStm => ObjectStream, 
    :EmbeddedFile => EmbeddedFileStream,
    :Metadata => MetadataStream,
    :XRef => XRefStream,
    :"3D" => U3DStream
  }
  
  STM_XOBJ_SUBTYPES = #:nodoc:
  {
    :Image => Graphics::ImageXObject,
    :Form => Graphics::FormXObject
  }

  class InvalidPDFError < Exception #:nodoc:
  end
	
  #
  # Main class representing a PDF file and its inner contents.
  # A PDF file contains a set of Revision.
  #
  class PDF
  
    #
    # Class representing a particular revision in a PDF file.
    # Revision contains :
    # * A Body, which is a sequence of Object.
    # * A XRef::Section, holding XRef information about objects in body.
    # * A Trailer.
    #
    class Revision
      attr_accessor :pdf
      attr_accessor :body, :xreftable, :xrefstm, :trailer
      
      def initialize(pdf)
        @pdf = pdf
        @body = {}
        @xreftable = nil
        @xrefstm = nil
        @trailer = nil
      end

      def trailer=(trl)
        trl.pdf = @pdf
        @trailer = trl
      end

      def has_xreftable?
        not @xreftable.nil?
      end

      def has_xrefstm?
        not @xrefstm.nil?
      end

      def objects
        @body.values
      end
    end

    attr_accessor :header, :revisions
    
    class << self
      
      #
      # Reads and parses a PDF file from disk.
      #
      def read(filename, options = {})
        filename = File.expand_path(filename) if filename.is_a?(::String)
        PDF::LinearParser.new(options).parse(filename)
      end

      #
      # Creates a new PDF and saves it.
      # If a block is passed, the PDF instance can be processed before saving.
      #
      def create(output, options = {})
        pdf = PDF.new
        yield(pdf) if block_given?
        pdf.save(output, options)
      end
      
      #
      # Deserializes a PDF dump.
      #
      def deserialize(filename)
        Zlib::GzipReader.open(filename) { |gz|
          pdf = Marshal.load(gz.read)
        }
        
        pdf
      end
    end
    
    #
    # Creates a new PDF instance.
    # _parser_:: The Parser object creating the document. If none is specified, some default structures are automatically created to get a minimal working document. 
    #
    def initialize(parser = nil)
      @header = PDF::Header.new
      @revisions = []
      
      add_new_revision
      @revisions.first.trailer = Trailer.new

      if parser
        @parser = parser
      else
        init
      end
    end
    
    #
    # Original file name if parsed from disk, nil otherwise.
    #
    def original_filename
      @parser.target_filename if @parser
    end

    #
    # Original file size if parsed from a data stream, nil otherwise.
    #
    def original_filesize
      @parser.target_filesize if @parser
    end

    #
    # Original data parsed to create this document, nil if created from scratch.
    #
    def original_data
      @parser.target_data if @parser
    end
   
    #
    # Serializes the current PDF.
    #
    def serialize(filename)
      parser = @parser
      @parser = nil # do not serialize the parser

      Zlib::GzipWriter.open(filename) { |gz|
        gz.write Marshal.dump(self)
      }
      
      @parser = parser
      self
    end
    
    #
    # Saves the current document. 
    # _filename_:: The path where to save this PDF.
    #
    def save(path, params = {})
      
      options = 
      {
        :delinearize => true,
        :recompile => true,
        :decrypt => false
      }
      options.update(params)

      if self.frozen? # incompatible flags with frozen doc (signed)
        options[:recompile] = 
        options[:rebuildxrefs] = 
        options[:noindent] = 
        options[:obfuscate] = false
      end
      
      if path.respond_to?(:write)
        fd = path
      else
        path = File.expand_path(path)
        fd = File.open(path, 'w').binmode
      end
      
      intents_as_pdfa1 if options[:intent] =~ /pdf[\/-]?A1?/i
      self.delinearize! if options[:delinearize] and self.is_linearized?
      compile(options) if options[:recompile]

      fd.write output(options)
      fd.close
      
      self
    end
    alias saveas save
    
    #
    # Saves the file up to given revision number.
    # This can be useful to visualize the modifications over different incremental updates.
    # _revision_:: The revision number to save.
    # _filename_:: The path where to save this PDF.
    #
    def save_upto(revision, filename)
      save(filename, :up_to_revision => revision)  
    end

    #
    # Returns an array of Objects whose content is matching _pattern_.
    #
#    def grep(*patterns)
#
#      patterns.map! do |pattern|
#        pattern.is_a?(::String) ? Regexp.new(Regexp.escape(pattern)) : pattern
#      end
#
#      unless patterns.all? { |pattern| pattern.is_a?(Regexp) }
#        raise TypeError, "Expected a String or Regexp"
#      end
#
#      result = []
#      objects.each do |obj|
#        begin
#          case obj
#            when String, Name
#              result << obj if patterns.any?{|pattern| obj.value.to_s.match(pattern)}
#            when Stream
#              result << obj if patterns.any?{|pattern| obj.data.match(pattern)}
#          end
#        rescue Exception => e
#          puts "[#{e.class}] #{e.message}"
#
#          next
#        end
#      end
#
#      result
#    end

    #
    # Returns an array of strings and streams matching the given pattern.
    #
    def grep(*patterns) #:nodoc:
      patterns.map! do |pattern|
        if pattern.is_a?(::String)
          Regexp.new(Regexp.escape(pattern), Regexp::IGNORECASE)
        else
          pattern
        end
      end

      unless patterns.all? { |pattern| pattern.is_a?(Regexp) }
        raise TypeError, "Expected a String or Regexp"
      end

      objset = []
      self.indirect_objects.each do |indobj|
        case indobj
          when Stream then
            objset.push indobj
            objset.concat(indobj.dictionary.strings_cache)
            objset.concat(indobj.dictionary.names_cache)
          when Name,String then objset.push indobj
          when Dictionary,Array then 
            objset.concat(indobj.strings_cache)
            objset.concat(indobj.names_cache)
        end
      end

      objset.delete_if do |obj|
        begin
          case obj
            when String, Name
              not patterns.any?{|pattern| obj.value.to_s.match(pattern)}
            when Stream
              not patterns.any?{|pattern| obj.data.match(pattern)}
          end
        rescue Exception => e
          true
        end
      end
    end

    #
    # Returns an array of Objects whose name (in a Dictionary) is matching _pattern_.
    #
    def ls(*patterns)
      return objects(:include_keys => false) if patterns.empty?

      result = []

      patterns.map! do |pattern|
        pattern.is_a?(::String) ? Regexp.new(Regexp.escape(pattern)) : pattern
      end

      objects(:only_keys => true).each do |key|
        if patterns.any?{ |pattern| key.value.to_s.match(pattern) }
          value = key.parent[key]
          result << ( value.is_a?(Reference) ? value.solve : value )
        end
      end

      result
    end

    #
    # Returns an array of Objects whose name (in a Dictionary) is matching _pattern_.
    # Do not follow references.
    #
    def ls_no_follow(*patterns)
      return objects(:include_keys => false) if patterns.empty?

      result = []

      patterns.map! do |pattern|
        pattern.is_a?(::String) ? Regexp.new(Regexp.escape(pattern)) : pattern
      end

      objects(:only_keys => true).each do |key|
        if patterns.any?{ |pattern| key.value.to_s.match(pattern) }
          value = key.parent[key]
          result << value
        end
      end

      result
    end

    #
    # Returns an array of objects matching specified block.
    #
    def find(params = {}, &b)
      
      options =
      {
        :only_indirect => false
      }
      options.update(params)
      
      objset = (options[:only_indirect] == true) ? 
        self.indirect_objects : self.objects

      objset.find_all(&b)
    end
    
    #
    # Returns an array of objects embedded in the PDF body.
    # _include_objstm_:: Whether it shall return objects embedded in object streams.
    # Note : Shall return to an iterator for Ruby 1.9 comp.
    #
    def objects(params = {})
      
      def append_subobj(root, objset, opts)
        
        if objset.find{ |o| root.equal?(o) }.nil?
          objset << root unless opts[:only_keys]

          if root.is_a?(Dictionary)
            root.each_pair { |name, value|
              objset << name if opts[:only_keys]

              append_subobj(name, objset, opts) if opts[:include_keys] and not opts[:only_keys]
              append_subobj(value, objset, opts)
            }
          elsif root.is_a?(Array) or (root.is_a?(ObjectStream) and opts[:include_objectstreams])
            root.each { |subobj| append_subobj(subobj, objset, opts) }
          end
        end
      end

      options =
      {
        :include_objectstreams => true,
        :include_keys => true,
        :only_keys => false
      }
      options.update(params)

      options[:include_keys] |= options[:only_keys]
      
      objset = []
      @revisions.each do |revision|
        revision.objects.each do |object|
            append_subobj(object, objset, options)
        end
      end
      
      objset
    end
    
    #
    # Return an array of indirect objects.
    #
    def indirect_objects
      @revisions.inject([]) do |set, rev| set.concat(rev.objects) end
    end
    alias :root_objects :indirect_objects
    
    #
    # Adds a new object to the PDF file.
    # If this object has no version number, then a new one will be automatically computed and assignated to him.
    # It returns a Reference to this Object.
    # _object_:: The object to add.
    #
    def <<(object)
      add_to_revision(object, @revisions.last)
    end
    alias :insert :<<
    
    #
    # Adds a new object to a specific revision.
    # If this object has no version number, then a new one will be automatically computed and assignated to him.
    # It returns a Reference to this Object.
    # _object_:: The object to add.
    # _revision_:: The revision to add the object to.
    #
    def add_to_revision(object, revision)
     
      object.set_indirect(true)
      object.set_pdf(self)
      
      object.no, object.generation = alloc_new_object_number if object.no == 0
      
      revision.body[object.reference] = object
      
      object.reference
    end

    #
    # Ends the current Revision, and starts a new one.
    #
    def add_new_revision
      
      root = @revisions.last.trailer[:Root] unless @revisions.empty?

      @revisions << Revision.new(self)
      @revisions.last.trailer = Trailer.new
      @revisions.last.trailer.Root = root

      self
    end

    #
    # Removes a whole document revision.
    # _index_:: Revision index, first is 0.
    #
    def remove_revision(index)
      if index < 0 or index > @revisions.size
        raise IndexError, "Not a valid revision index"
      end

      if @revisions.size == 1
        raise InvalidPDFError, "Cannot remove last revision"
      end

      @revisions.delete_at(index)
      self
    end
    
    #
    # Looking for an object present at a specified file offset.
    #
    def get_object_by_offset(offset) #:nodoc:
      self.indirect_objects.find { |obj| obj.file_offset == offset }
    end   

    #
    # Remove an object.
    #
    def delete_object(no, generation = 0)
      
      case no
        when Reference
          target = no
        when ::Integer
          target = Reference.new(no, generation)
      else
        raise TypeError, "Invalid parameter type : #{no.class}" 
      end
      
      @revisions.each do |rev|
        rev.body.delete(target)
      end

    end

    #
    # Search for an indirect object in the document.
    # _no_:: Reference or number of the object.
    # _generation_:: Object generation.
    #
    def get_object(no, generation = 0, use_xrefstm = true) #:nodoc:
      case no
        when Reference
          target = no
        when ::Integer
           target = Reference.new(no, generation)
        when Origami::Object
          return no
      else
        raise TypeError, "Invalid parameter type : #{no.class}" 
      end
      
      set = indirect_objects_table
     
      #
      # Search through accessible indirect objects.
      #
      if set.include?(target)
        set[target]
      elsif use_xrefstm == true
        # Look into XRef streams.

        if @revisions.last.has_xrefstm?
          xrefstm = @revisions.last.xrefstm

          done = []
          while xrefstm.is_a?(XRefStream) and not done.include?(xrefstm)
            xref = xrefstm.find(target.refno)
            
            #
            # We found a matching XRef.
            #
            if xref.is_a?(XRefToCompressedObj)
              objstm = get_object(xref.objstmno, 0, false)

              object = objstm.extract_by_index(xref.index)
              if object.is_a?(Origami::Object) and object.no == target.refno
                return object
              else
                return objstm.extract(target.refno)
              end
            elsif xrefstm.has_field?(:Prev)
              done << xrefstm
              xrefstm = get_object_by_offset(xrefstm.Prev)
            else
              break
            end
          end
        end

        #
        # Lastly search directly into Object streams (might be very slow).
        #
        stream = set.values.find_all{|obj| obj.is_a?(ObjectStream)}.find do |objstm| objstm.include?(target.refno) end
        stream && stream.extract(target.refno)
      end
      
    end

    alias :[] :get_object
  
    #
    # Returns a new number/generation for future object.
    #
    def alloc_new_object_number
      no = 1

      # Deprecated number allocation policy (first available)
      #no = no + 1 while get_object(no)

      objset = self.indirect_objects
      self.indirect_objects.find_all{|obj| obj.is_a?(ObjectStream)}.each do |objstm|
        objstm.each{|obj| objset << obj}
      end

      allocated = objset.collect{|obj| obj.no}.compact
      no = allocated.max + 1 unless allocated.empty?

      [ no, 0 ]
    end
    
    ##########################
    private
    ##########################
    
    #
    # Compute and update XRef::Section for each Revision.
    #
    def rebuildxrefs
      
      size = 0
      startxref = @header.to_s.size
      
      @revisions.each do |revision|
      
        revision.objects.each do |object|
          startxref += object.to_s.size
        end
        
        size += revision.body.size
        revision.xreftable = buildxrefs(revision.objects)
        
        revision.trailer ||= Trailer.new
        revision.trailer.Size = size + 1
        revision.trailer.startxref = startxref
        
        startxref += revision.xreftable.to_s.size + revision.trailer.to_s.size
      end
      
      self
    end
    
    #
    # This method is meant to recompute, verify and correct main PDF structures, in order to output a proper file.
    # * Allocates objects references.
    # * Sets some objects missing required values.
    #
    def compile(options = {})

      #
      # A valid document must have at least one page.
      #
      append_page if pages.empty?
     
      #
      # Allocates object numbers and creates references.
      # Invokes object finalization methods.
      #
      if self.is_a?(Encryption::EncryptedDocument)
        physicalize(options)
      else
        physicalize
      end
            
      #
      # Sets the PDF version header.
      #
      version, level = version_required
      @header.majorversion = version[0,1].to_i
      @header.minorversion = version[2,1].to_i

      set_extension_level(version, level) if level > 0
      
      self
    end
    
    #
    # Cleans the document from its references.
    # Indirects objects are made direct whenever possible.
    # TODO: Circuit-checking to avoid infinite induction
    #
    def logicalize #:nodoc:

      fail "Not yet supported"

      processed = []
      
      def convert(root) #:nodoc:

        replaced = []
        if root.is_a?(Dictionary) or root.is_a?(Array)
          
          root.each { |obj|
            convert(obj)
          }

          root.map! { |obj|
            if obj.is_a?(Reference)
              target = obj.solve
              # Streams can't be direct objects
              if target.is_a?(Stream)
                obj
              else
                replaced << obj
                target
              end
            else
              obj
            end
          }
          
        end

        replaced
      end

      @revisions.each do |revision|
        revision.objects.each do |obj|
          processed.concat(convert(obj))
        end
      end

    end
    
    #
    # Converts a logical PDF view into a physical view ready for writing.
    #
    def physicalize
     
      #
      # Indirect objects are added to the revision and assigned numbers.
      #
      def build(obj, revision) #:nodoc:

        #
        # Finalize any subobjects before building the stream.
        #
        if obj.is_a?(ObjectStream)
          obj.each do |subobj|
            build(subobj, revision)
          end
        end
  
        obj.pre_build

        if obj.is_a?(Dictionary) or obj.is_a?(Array)
            
            obj.map! do |subobj|
              if subobj.is_indirect?
                if get_object(subobj.reference)
                  subobj.reference
                else
                  ref = add_to_revision(subobj, revision)
                  build(subobj, revision)
                  ref
                end
              else
                subobj
              end
            end
            
            obj.each do |subobj|
              build(subobj, revision)
            end
            
        elsif obj.is_a?(Stream)
          build(obj.dictionary, revision)
        end

        obj.post_build
        
      end
      
      indirect_objects_by_rev.each do |obj, revision|
          build(obj, revision)          
      end
      
      self
    end

    #
    # Returns the final binary representation of the current document.
    #
    def output(params = {})
   
      has_objstm = self.indirect_objects.any?{|obj| obj.is_a?(ObjectStream)}

      options =
      {
        :rebuildxrefs => true,
        :noindent => false,
        :obfuscate => false,
        :use_xrefstm => has_objstm,
        :use_xreftable => (not has_objstm),
        :up_to_revision => @revisions.size
      }
      options.update(params)

      options[:up_to_revision] = @revisions.size if options[:up_to_revision] > @revisions.size

      # Reset to default params if no xrefs are chosen (hybrid files not supported yet)
      if options[:use_xrefstm] == options[:use_xreftable]
        options[:use_xrefstm] = has_objstm
        options[:use_xreftable] = (not has_objstm)
      end

      # Get trailer dictionary
      trailer_info = get_trailer_info
      if trailer_info.nil?
        raise InvalidPDFError, "No trailer information found"
      end
      trailer_dict = trailer_info.dictionary
 
      prev_xref_offset = nil
      xrefstm_offset = nil
      xreftable_offset = nil
    
      # Header
      bin = ""
      bin << @header.to_s
      
      # For each revision
      @revisions[0, options[:up_to_revision]].each do |rev|
        
        # Create xref table/stream.
        if options[:rebuildxrefs] == true
          lastno_table, lastno_stm = 0, 0
          brange_table, brange_stm = 0, 0
          
          xrefs_stm = [ XRef.new(0, 0, XRef::FREE) ]
          xrefs_table = [ XRef.new(0, XRef::FIRSTFREE, XRef::FREE) ]

          if options[:use_xreftable] == true
            xrefsection = XRef::Section.new
          end

          if options[:use_xrefstm] == true
            xrefstm = rev.xrefstm || XRefStream.new
            if xrefstm == rev.xrefstm
              xrefstm.clear
            else
              add_to_revision(xrefstm, rev) 
            end
          end
        end
       
        objset = rev.objects
        
        objset.find_all{|obj| obj.is_a?(ObjectStream)}.each do |objstm|
          objset.concat objstm.objects
        end if options[:rebuildxrefs] == true and options[:use_xrefstm] == true

        # For each object, in number order
        objset.sort.each do |obj|
         
          # Create xref entry.
          if options[:rebuildxrefs] == true
           
            # Adding subsections if needed
            if options[:use_xreftable] and (obj.no - lastno_table).abs > 1
              xrefsection << XRef::Subsection.new(brange_table, xrefs_table)

              xrefs_table.clear
              brange_table = obj.no
            end
            if options[:use_xrefstm] and (obj.no - lastno_stm).abs > 1
              xrefs_stm.each do |xref| xrefstm << xref end
              xrefstm.Index ||= []
              xrefstm.Index << brange_stm << xrefs_stm.length

              xrefs_stm.clear
              brange_stm = obj.no
            end

            # Process embedded objects
            if options[:use_xrefstm] and obj.parent != obj and obj.parent.is_a?(ObjectStream)
              index = obj.parent.index(obj.no)
             
              xrefs_stm << XRefToCompressedObj.new(obj.parent.no, index)
              
              lastno_stm = obj.no
            else
              xrefs_stm << XRef.new(bin.size, obj.generation, XRef::USED)
              xrefs_table << XRef.new(bin.size, obj.generation, XRef::USED)

              lastno_table = lastno_stm = obj.no
            end

          end
         
          if obj.parent == obj or not obj.parent.is_a?(ObjectStream)
           
            # Finalize XRefStm
            if options[:rebuildxrefs] == true and options[:use_xrefstm] == true and obj == xrefstm
              xrefstm_offset = bin.size
   
              xrefs_stm.each do |xref| xrefstm << xref end

              xrefstm.W = [ 1, (xrefstm_offset.to_s(2).size + 7) >> 3, 2 ]
              if xrefstm.DecodeParms.is_a?(Dictionary) and xrefstm.DecodeParms.has_key?(:Columns)
                xrefstm.DecodeParms[:Columns] = xrefstm.W[0] + xrefstm.W[1] + xrefstm.W[2]
              end

              xrefstm.Index ||= []
              xrefstm.Index << brange_stm << xrefs_stm.size
   
              xrefstm.dictionary = xrefstm.dictionary.merge(trailer_dict) 
              xrefstm.Prev = prev_xref_offset
              rev.trailer.dictionary = nil

              add_to_revision(xrefstm, rev)

              xrefstm.pre_build
              xrefstm.post_build
            end

            # Output object code
            if (obj.is_a?(Dictionary) or obj.is_a?(Stream)) and options[:noindent]
              bin << obj.to_s(0)
            else
              bin << obj.to_s
            end
          end
        end
      
        rev.trailer ||= Trailer.new
        
        # XRef table
        if options[:rebuildxrefs] == true
 
          if options[:use_xreftable] == true
            table_offset = bin.size
            
            xrefsection << XRef::Subsection.new(brange_table, xrefs_table)
            rev.xreftable = xrefsection
 
            rev.trailer.dictionary = trailer_dict
            rev.trailer.Size = objset.size + 1
            rev.trailer.Prev = prev_xref_offset

            rev.trailer.XRefStm = xrefstm_offset if options[:use_xrefstm] == true
          end

          startxref = options[:use_xreftable] == true ? table_offset : xrefstm_offset
          rev.trailer.startxref = prev_xref_offset = startxref

        end # end each rev
        
        # Trailer
        bin << rev.xreftable.to_s if options[:use_xreftable] == true
        bin << (options[:obfuscate] == true ? rev.trailer.to_obfuscated_str : rev.trailer.to_s)
        
      end
      
      bin
    end
    
    #
    # Instanciates basic structures required for a valid PDF file.
    #
    def init
      catalog = (self.Catalog = (get_doc_attr(:Root) || Catalog.new))
      catalog.Pages = PageTreeNode.new.set_indirect(true)
      @revisions.last.trailer.Root = catalog.reference

      self
    end
    
    def filesize #:nodoc:
      output(:rebuildxrefs => false).size
    end
    
    def version_required #:nodoc:
      
      max = [ 1.0, 0 ]
      @revisions.each { |revision|
        revision.objects.each { |object|
          current = object.pdf_version_required
          max = current if (current <=> max) > 0
        }
      }
      max[0] = max[0].to_s
      
      max
    end
    
    def indirect_objects_table #:nodoc:
      @revisions.inject({}) do |set, rev| set.merge(rev.body) end
    end
 
    def indirect_objects_by_rev #:nodoc:
      @revisions.inject([]) do |set,rev|
        objset = rev.objects
        set.concat(objset.zip(::Array.new(objset.length, rev))) 
      end
    end
    
    #
    # Compute and update XRef::Section for each Revision.
    #
    def rebuild_dummy_xrefs #:nodoc
      
      def build_dummy_xrefs(objects)
        
        lastno = 0
        brange = 0
        
        xrefs = [ XRef.new(0, XRef::FIRSTFREE, XRef::FREE) ]

        xrefsection = XRef::Section.new
        objects.sort.each { |object|
          if (object.no - lastno).abs > 1
            xrefsection << XRef::Subsection.new(brange, xrefs)
            brange = object.no
            xrefs.clear
          end
          
          xrefs << XRef.new(0, 0, XRef::FREE)

          lastno = object.no
        }
        
        xrefsection << XRef::Subsection.new(brange, xrefs)
        
        xrefsection
      end
      
      size = 0
      startxref = @header.to_s.size
      
      @revisions.each do |revision|
        revision.objects.each do |object|
          startxref += object.to_s.size
        end
        
        size += revision.body.size
        revision.xreftable = build_dummy_xrefs(revision.objects)
        
        revision.trailer ||= Trailer.new
        revision.trailer.Size = size + 1
        revision.trailer.startxref = startxref
        
        startxref += revision.xreftable.to_s.size + revision.trailer.to_s.size
      end
      
      self
    end
    
    #
    # Build a xref section from a set of objects.
    #
    def buildxrefs(objects) #:nodoc:
      
      lastno = 0
      brange = 0
      
      xrefs = [ XRef.new(0, XRef::FIRSTFREE, XRef::FREE) ]
      
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
    
    def delete_revision(ngen) #:nodoc:
      @revisions.delete_at[ngen]
    end
    
    def get_revision(ngen) #:nodoc:
      @revisions[ngen].body
    end
    
    def get_object_offset(no,generation) #:nodoc:
      objectoffset = @header.to_s.size
      
      @revisions.each do |revision|
        revision.objects.sort.each do |object|
          if object.no == no and object.generation == generation then return objectoffset
          else
            objectoffset += object.to_s.size
          end
        end
        
        objectoffset += revision.xreftable.to_s.size
        objectoffset += revision.trailer.to_s.size
      end
      
      nil
    end

	end

end

