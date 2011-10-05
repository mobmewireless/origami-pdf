=begin

= File
	catalog.rb

= Info
	This file is part of Origami, PDF manipulation framework for Ruby
	Copyright (C) 2010	Guillaume Delugr» <guillaume@security-labs.org>
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

module Origami

  class PDF

    #
    # Sets PDF extension level and version. Only supported values are "1.7" and 3.
    #
    def set_extension_level(version, level)
      exts = (self.Catalog.Extensions ||= Extensions.new)

      exts[:ADBE] = DeveloperExtension.new
      exts[:ADBE].BaseVersion = Name.new(version)
      exts[:ADBE].ExtensionLevel = level

      self
    end

    #
    # Returns the current Catalog Dictionary.
    #
    def Catalog
      cat = get_doc_attr(:Root)

      case cat
        when Catalog then
          cat
        when Dictionary then
          casted = Catalog.new(cat)
          casted.no, casted.generation = cat.no, cat.generation
          casted.set_indirect(true)
          casted.set_pdf(self)

          casted
        else
          raise InvalidPDFError, "Broken catalog"
      end
    end
    
    #
    # Sets the current Catalog Dictionary.
    #
    def Catalog=(cat)
      #unless cat.is_a?(Catalog)
      #  raise TypeError, "Expected type Catalog, received #{cat.class}"
      #end
      cat = Catalog.new(cat) unless cat.is_a? Catalog
      
      if @revisions.last.trailer.Root
        delete_object(@revisions.last.trailer[:Root])
      end
      
      @revisions.last.trailer.Root = self << cat
    end
 
    #
    # Sets an action to run on document opening.
    # _action_:: An Action Object.
    #
    def onDocumentOpen(action)   
      
      unless action.is_a?(Action) or action.is_a?(Destination) or action.is_a?(Reference)
        raise TypeError, "An Action object must be passed."
      end
      
      unless self.Catalog
        raise InvalidPDFError, "A catalog object must exist to add this action."
      end
      
      self.Catalog.OpenAction = action
      
      self
    end
    
    #
    # Sets an action to run on document closing.
    # _action_:: A JavaScript Action Object.
    #
    def onDocumentClose(action)
      
      unless action.is_a?(Action::JavaScript) or action.is_a?(Reference)
        raise TypeError, "An Action::JavaScript object must be passed."
      end
      
      unless self.Catalog
        raise InvalidPDFError, "A catalog object must exist to add this action."
      end
      
      self.Catalog.AA ||= CatalogAdditionalActions.new
      self.Catalog.AA.WC = action
      
      self
    end
    
    #
    # Sets an action to run on document printing.
    # _action_:: A JavaScript Action Object.
    #
    def onDocumentPrint(action)
      
      unless action.is_a?(Action::JavaScript) or action.is_a?(Reference)
        raise TypeError, "An Action::JavaScript object must be passed."
      end
      
      unless self.Catalog
        raise InvalidPDFError, "A catalog object must exist to add this action."
      end
      
      self.Catalog.AA ||= CatalogAdditionalActions.new
      self.Catalog.AA.WP = action
      
    end

    #
    # Registers an object into a specific Names root dictionary.
    # _root_:: The root dictionary (see Names::Root)
    # _name_:: The value name.
    # _value_:: The value to associate with this name.
    #
    def register(root, name, value)
      self.Catalog.Names ||= Names.new
      
      value.set_indirect(true) unless value.is_a? Reference
      
      namesroot = self.Catalog.Names[root]
      if namesroot.nil?
        names = NameTreeNode.new(:Names => []).set_indirect(true)
        self.Catalog.Names[root] = names
        names.Names << name << value
      else
        namesroot.solve[:Names] << name << value
      end
    end

    def each_name(root, &b)
      namesroot = get_names_root(root)
      return if namesroot.nil?
   
      each_name_from_node(namesroot, [], &b)
      self
    end

    #
    # Retrieve the corresponding value associated with _name_ in
    # the specified _root_ name directory, or nil if the value does
    # not exist.
    #
    def resolve_name(root, name)
      namesroot = get_names_root(root)
      return nil if namesroot.nil?

      resolve_name_from_node(namesroot, name)
    end

    #
    # Returns a Hash of all names under specified _root_ name directory.
    # Returns nil if the directory does not exist.
    #
    def ls_names(root)
      namesroot = get_names_root(root)
      return {} if namesroot.nil?

      names = names_from_node(namesroot)
      if names.length % 2 != 0
        return InvalidNameTreeError, "Odd number of elements"
      end

      Hash[*names]
    end

    private

    def names_from_node(node, browsed_nodes = []) #:nodoc:
      children = []

      unless browsed_nodes.any? {|browsed| browsed.equal?(node)}
        browsed_nodes.push(node)
        if node.has_key?(:Names) # leaf node
          children.concat(node.Names)
        elsif node.has_key?(:Kids) # intermediate node
          node.Kids.each do |kid|
            children.concat(names_from_node(kid.solve, browsed_nodes))
          end
        end
      end

      children
    end

    def resolve_name_from_node(node, name, browsed_nodes = []) #:nodoc:
      unless browsed_nodes.any? {|browsed| browsed.equal?(node)}
        browsed_nodes.push(node)

        if node.has_key?(:Names) # leaf node
          limits = node.Limits

          if limits
            min, max = limits[0].value, limits[1].value          
            if (min..max) === name.to_str
              names = Hash[*node.Names]
              target = names[name]
              return target && target.solve
            end
          else
            names = Hash[*node.Names]
            target = names[name]
            return target && target.solve
          end

        elsif node.has_key?(:Kids) # intermediate node
          node.Kids.each do |kid|
            kid = kid.solve
            limits = kid.Limits
            min, max = limits[0].value, limits[1].value          
            
            if (min..max) === name.to_str
              return resolve_name_from_node(kid, name, browsed_nodes)
            end
          end
        end
      end
    end

    def each_name_from_node(node, browsed_nodes = [], &b) #:nodoc:
      if node.has_key?(:Names) # leaf node
        names = Hash[*node.Names]
        names.each_pair do |name, value|
          b.call(name, value.solve)
        end
      elsif node.has_key?(:Kids) # intermediate node
        node.Kids.each do |kid|
          each_name_from_node(kid.solve, browsed_nodes, &b)
        end
      end
    end

    def get_names_root(root) #:nodoc:
      namedirs = self.Catalog.Names
      return nil if namedirs.nil? or namedirs[root].nil?

      namedirs[root].solve
    end
  end

  module PageLayout #:nodoc:
    SINGLE            = :SinglePage
    ONE_COLUMN        = :OneColumn
    TWO_COLUMN_LEFT   = :TwoColumnLeft
    TWO_COLUMN_RIGHT  = :TwoColumnRight
    TWO_PAGE_LEFT     = :TwoPageLeft
    TWO_PAGE_RIGHT    = :TwoPageRight
  end

  module PageMode #:nodoc:
    NONE        = :UseNone
    OUTLINES    = :UseOutlines
    THUMBS      = :UseThumbs
    FULLSCREEN  = :FullScreen
    OPTIONAL_CONTENT = :UseOC
    ATTACHMENTS = :UseAttachments
  end

  #
  # Class representing the Catalog Dictionary of a PDF file.
  #
  class Catalog < Dictionary
    
    include StandardObject

    field   :Type,                :Type => Name, :Default => :Catalog, :Required => true
    field   :Version,             :Type => Name, :Version => "1.4"
    field   :Pages,               :Type => Dictionary, :Required => true
    field   :PageLabels,          :Type => Dictionary, :Version => "1.3"
    field   :Names,               :Type => Dictionary, :Version => "1.2"
    field   :Dests,               :Type => Dictionary, :Version => "1.1"
    field   :ViewerPreferences,   :Type => Dictionary, :Version => "1.2"  
    field   :PageLayout,          :Type => Name, :Default => PageLayout::SINGLE
    field   :PageMode,            :Type => Name, :Default => PageMode::NONE
    field   :Outlines,            :Type => Dictionary
    field   :Threads,             :Type => Array, :Version => "1.1"
    field   :OpenAction,          :Type => [ Array, Dictionary ], :Version => "1.1"
    field   :AA,                  :Type => Dictionary, :Version => "1.4"
    field   :URI,                 :Type => Dictionary, :Version => "1.1"
    field   :AcroForm,            :Type => Dictionary, :Version => "1.2"
    field   :Metadata,            :Type => Stream, :Version => "1.4"
    field   :StructTreeRoot,      :Type => Dictionary, :Version => "1.3"
    field   :MarkInfo,            :Type => Dictionary, :Version => "1.4"
    field   :Lang,                :Type => String, :Version => "1.4"
    field   :SpiderInfo,          :Type => Dictionary, :Version => "1.3"
    field   :OutputIntents,       :Type => Array, :Version => "1.4"
    field   :PieceInfo,           :Type => Dictionary, :Version => "1.4"
    field   :OCProperties,        :Type => Dictionary, :Version => "1.5"
    field   :Perms,               :Type => Dictionary, :Version => "1.5"
    field   :Legal,               :Type => Dictionary, :Version => "1.5"
    field   :Requirements,        :Type => Array, :Version => "1.7"
    field   :Collection,          :Type => Dictionary, :Version => "1.7"
    field   :NeedsRendering,      :Type => Boolean, :Version => "1.7", :Default => false
    field   :Extensions,          :Type => Dictionary, :Version => "1.7", :ExtensionLevel => 3

    def initialize(hash = {})
      set_indirect(true)

      super(hash)
    end
    
  end
  
  #
  # Class representing additional actions which can be associated with a Catalog.
  #
  class CatalogAdditionalActions < Dictionary
    include StandardObject
   
    field   :WC,                  :Type => Dictionary, :Version => "1.4"
    field   :WS,                  :Type => Dictionary, :Version => "1.4"
    field   :DS,                  :Type => Dictionary, :Version => "1.4"
    field   :WP,                  :Type => Dictionary, :Version => "1.4"
    field   :DP,                  :Type => Dictionary, :Version => "1.4"
  end
  
  class InvalidNameTreeError < Exception #:nodoc:
  end

  #
  # Class representing the Names Dictionary of a PDF file.
  #
  class Names < Dictionary
    include StandardObject
    
    #
    # Defines constants for Names tree root entries.
    #
    module Root
      DESTS = :Dests
      AP = :AP
      JAVASCRIPT = :JavaScript
      PAGES = :Pages
      TEMPLATES = :Templates
      IDS = :IDS
      URLS = :URLS
      EMBEDDEDFILES = :EmbeddedFiles
      ALTERNATEPRESENTATIONS = :AlternatePresentations
      RENDITIONS = :Renditions
      XFARESOURCES = :XFAResources
    end

    field   Root::DESTS,        :Type => Dictionary, :Version => "1.2"
    field   Root::AP,           :Type => Dictionary, :Version => "1.3"
    field   Root::JAVASCRIPT,   :Type => Dictionary, :Version => "1.3"
    field   Root::PAGES,        :Type => Dictionary, :Version => "1.3"
    field   Root::TEMPLATES,    :Type => Dictionary, :Version => "1.3"
    field   Root::IDS,          :Type => Dictionary, :Version => "1.3"
    field   Root::URLS,         :Type => Dictionary, :Version => "1.3"
    field   Root::EMBEDDEDFILES,  :Type => Dictionary, :Version => "1.4"
    field   Root::ALTERNATEPRESENTATIONS, :Type => Dictionary, :Version => "1.4"
    field   Root::RENDITIONS,   :Type => Dictionary, :Version => "1.5"
    field   Root::XFARESOURCES, :Type => Dictionary, :Version => "1.7", :ExtensionLevel => 3
  end
  
  #
  # Class representing a node in a Name tree.
  #
  class NameTreeNode < Dictionary
    include StandardObject
   
    field   :Kids,              :Type => Array
    field   :Names,             :Type => Array
    field   :Limits,            :Type => Array
  end
  
  #
  # Class representing a leaf in a Name tree.
  #
  class NameLeaf < Origami::Array
    
    #
    # Creates a new leaf in a Name tree.
    # _hash_:: A hash of couples, associating a Name with an Reference.
    #
    def initialize(hash = {})
      
      names = []
      hash.each_pair do |k,v|
        names << k.to_o << v.to_o
      end
      
      super(names)
    end
  end

  #
  # Class representing the ViewerPreferences Dictionary of a PDF.
  # This dictionary modifies the way the UI looks when the file is opened in a viewer.
  #
  class ViewerPreferences < Dictionary
    include StandardObject

    field   :HideToolbar,             :Type => Boolean, :Default => false
    field   :HideMenubar,             :Type => Boolean, :Default => false
    field   :HideWindowUI,            :Type => Boolean, :Default => false
    field   :FitWindow,               :Type => Boolean, :Default => false
    field   :CenterWindow,            :Type => Boolean, :Default => false
    field   :DisplayDocTitle,         :Type => Boolean, :Default => false, :Version => "1.4"
    field   :NonFullScreenPageMode,   :Type => Name, :Default => :UseNone
    field   :Direction,               :Type => Name, :Default => :L2R
    field   :ViewArea,                :Type => Name, :Default => :CropBox, :Version => "1.4"
    field   :ViewClip,                :Type => Name, :Default => :CropBox, :Version => "1.4"
    field   :PrintArea,               :Type => Name, :Default => :CropBox, :Version => "1.4"
    field   :PrintClip,               :Type => Name, :Default => :CropBox, :Version => "1.4"
    field   :PrintScaling,            :Type => Name, :Default => :AppDefault, :Version => "1.6"
    field   :Duplex,                  :Type => Name, :Default => :Simplex, :Version => "1.7"
    field   :PickTrayByPDFSize,       :Type => Boolean, :Version => "1.7"
    field   :PrintPageRange,          :Type => Array, :Version => "1.7"
    field   :NumCopies,               :Type => Integer, :Version => "1.7"
    field   :Enforce,                 :Type => Array, :Version => "1.7", :ExtensionLevel => 3
    
  end

  class Requirement < Dictionary
    include StandardObject

    class Handler < Dictionary
      include StandardObject

      module Type
        JS    = :JS
        NOOP  = :NoOp
      end

      field   :Type,                  :Type => Name, :Default => :ReqHandler
      field   :S,                     :Type => Name, :Default => Type::NOOP, :Required => true
      field   :Script,                :Type => ByteString
    end

    field   :Type,                    :Type => Name, :Default => :Requirement
    field   :S,                       :Type => Name, :Default => :EnableJavaScripts, :Version => "1.7", :Required => true
    field   :RH,                      :Type => Array
  end

  #
  # Class representing an extension Dictionary.
  #
  class Extensions < Dictionary
    include StandardObject

    field   :Type,                    :Type => Name, :Default => :Extensions
  end

  #
  # Class representing a developer extension.
  #
  class DeveloperExtension < Dictionary
    include StandardObject

    field   :Type,                    :Type => Name, :Default => :DeveloperExtensions
    field   :BaseVersion,             :Type => Name, :Required => true
    field   :ExtensionLevel,          :Type => Integer, :Required => true

  end
  
end
