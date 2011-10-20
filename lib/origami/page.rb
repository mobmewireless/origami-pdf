=begin

= File
	page.rb

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

module Origami

  class PDF

    def append_page(page = Page.new, *more)
      raise InvalidPDFError, "Invalid page tree" if not self.Catalog or not self.Catalog.Pages or not self.Catalog.Pages.is_a?(PageTreeNode)
      pages = [ page ].concat(more)
      
      treeroot = self.Catalog.Pages
      
      treeroot.Kids ||= [] #:nodoc:
      treeroot.Kids.concat(pages)
      treeroot.Count = treeroot.Kids.length
      
      pages.each do |page| 
        page.Parent = treeroot
      end
      
      self
    end

    def insert_page(index, page)
      raise InvalidPDFError, "Invalid page tree" if not self.Catalog or not self.Catalog.Pages or not self.Catalog.Pages.is_a?(PageTreeNode)

      self.Catalog.Pages.insert_page(index, page)
      self
    end

    #
    # Returns an array of Page
    #
    def pages
      raise InvalidPDFError, "Invalid page tree" if not self.Catalog or not self.Catalog.Pages or not self.Catalog.Pages.is_a?(PageTreeNode)
      
      self.Catalog.Pages.children
    end

    #
    # Iterate through each page, returns self.
    #
    def each_page(&b)
      raise InvalidPDFError, "Invalid page tree" if not self.Catalog or not self.Catalog.Pages or not self.Catalog.Pages.is_a?(PageTreeNode)
     
       self.Catalog.Pages.each_page(&b)
       self
    end

    #
    # Get the n-th Page object.
    #
    def get_page(n)
      raise InvalidPDFError, "Invalid page tree" if not self.Catalog or not self.Catalog.Pages or not self.Catalog.Pages.is_a?(PageTreeNode)

      self.Catalog.Pages.get_page(n)
    end

    #
    # Lookup page in the page name directory.
    #
    def get_page_by_name(name)
      resolve_name Names::Root::PAGES, name
    end

    #
    # Calls block for each named page.
    #
    def each_named_page(&b)
      each_name(Names::Root::PAGES, &b) 
    end

  end
  
  module ResourcesHolder

    def add_extgstate(name, extgstate)
      target = self.is_a?(Resources) ? self : (self.Resources ||= Resources.new)

      target.ExtGState ||= {}
      target.ExtGState[name] = extgstate

      self
    end

    def add_colorspace(name, colorspace)
      target = self.is_a?(Resources) ? self : (self.Resources ||= Resources.new)

      csdir = target[:ColorSpace] ||= {}
      (csdir.is_a?(Reference) ? csdir.solve : csdir)[name] = colorspace
    
      self
    end
    
    def add_pattern(name, pattern)
      target = self.is_a?(Resources) ? self : (self.Resources ||= Resources.new)

      target.Pattern ||= {}
      target.Pattern[name] = pattern
    
      self
    end
    
    def add_shading(name, shading)
      target = self.is_a?(Resources) ? self : (self.Resources ||= Resources.new)

      target.Shading ||= {}
      target.Shading[name] = shading
    
      self
    end

    def add_xobject(name, xobject)
      target = self.is_a?(Resources) ? self : (self.Resources ||= Resources.new)

      target.XObject ||= {}
      target.XObject[name] = xobject
    
      self
    end
    
    def add_font(name, font)
      target = self.is_a?(Resources) ? self : (self.Resources ||= Resources.new)

      target.Font ||= {}
      target.Font[name] = font
      
      self
    end

    def add_properties(name, properties)
      target = self.is_a?(Resources) ? self : (self.Resources ||= Resources.new)

      target.Properties ||= {}
      target.Properties[name] = properties
    
      self
    end
    
  end

  #
  # Class representing a Resources Dictionary for a Page.
  #
  class Resources < Dictionary
    
    include StandardObject
    include ResourcesHolder

    field   :ExtGState,   :Type => Dictionary
    field   :ColorSpace,  :Type => Dictionary
    field   :Pattern,     :Type => Dictionary
    field   :Shading,     :Type => Dictionary, :Version => "1.3"
    field   :XObject,     :Type => Dictionary
    field   :Font,        :Type => Dictionary
    field   :ProcSet,     :Type => Array
    field   :Properties,  :Type => Dictionary, :Version => "1.2"

    def pre_build
      unless self.Font
        fnt = Font::Type1::Standard::Helvetica.new.pre_build
        fnt.Name = :F1
        
        add_font(fnt.Name, fnt)
      end
      
      super
    end
    
  end

  #
  # Class representing a node in a Page tree.
  #
  class PageTreeNode < Dictionary
    include StandardObject
   
    field   :Type,          :Type => Name, :Default => :Pages, :Required => true
    field   :Parent,        :Type => Dictionary
    field   :Kids,          :Type => Array, :Default => [], :Required => true
    field   :Count,         :Type => Integer, :Default => 0, :Required => true

    def initialize(hash = {})
      self.Count = 0
      self.Kids = []

      super(hash)
      
      set_indirect(true)
    end

    def pre_build #:nodoc:
      self.Count = self.children.length     
         
      super
    end

    def insert_page(index, page)
      
      if index > self.Count
        raise IndexError, "Invalid index for page tree"
      end

      count = 0
      kids = self.Kids

      kids.length.times { |n|
        if count == index
          kids.insert(n, page)
          self.Count = self.Count + 1
          page.Parent = self
          return self
        else
          node = kids[n].is_a?(Reference) ? kids[n].solve : kids[n]
          case node
            when Page
              count = count + 1
              next
            when PageTreeNode
              if count + node.Count > index
                node.insert_page(index - count, page)
                self.Count = self.Count + 1
                return self
              else
                count = count + node.Count
                next
              end
          end
        end
      }

      if count == index
        self << page
      else
        raise IndexError, "An error occured while inserting page"
      end

      self
    end

    #
    # Returns an array of Page inheriting this tree node.
    #
    def children
      pageset = []
     
      unless self.Count.nil?
        [ self.Count.value, self.Kids.length ].min.times do |n|
          node = self.Kids[n].is_a?(Reference) ? self.Kids[n].solve : self.Kids[n]
          case node
            when PageTreeNode then pageset.concat(node.children) 
            when Page then pageset << node
          end
        end
      end
      
      pageset
    end

    #
    # Iterate through each page of that node.
    #
    def each_page(&b)
      unless self.Count.nil?
        [ self.Count.value, self.Kids.length ].min.times do |n|
          node = self.Kids[n].is_a?(Reference) ? self.Kids[n].solve : self.Kids[n]
          case node
            when PageTreeNode then node.each_page(&b)
            when Page then b.call(node)
          end
        end
      end
    end

    #
    # Get the n-th Page object in this node, starting from 1.
    #
    def get_page(n)
      raise IndexError, "Page numbers are referenced starting from 1" if n < 1

      decount = n
      loop do
        [ self.Count.value, self.Kids.length ].min.times do |i|
          node = self.Kids[i].is_a?(Reference) ? self.Kids[i].solve : self.Kids[i]

          case node
            when Page
              decount = decount - 1
              return node if decount == 0
            
            when PageTreeNode
              nchilds = [ node.Count.value, node.Kids.length ].min
              if nchilds >= decount
                return node.get_page(decount)
              else
                decount -= nchilds
              end
          end
        end
      end
    end
      
    def << (pageset)
      pageset = [pageset] unless pageset.is_a?(::Array)
      raise TypeError, "Cannot add anything but Page and PageTreeNode to this node" unless pageset.all? { |item| item.is_a?(Page) or item.is_a?(PageTreeNode) }

      self.Kids ||= Array.new
      self.Kids.concat(pageset)
      self.Count = self.Kids.length
        
      pageset.each do |node| 
        node.Parent = self 
      end
    end
  end
    
  #
  # Class representing a Page in the PDF document.
  #
  class Page < Dictionary
    
    include StandardObject
    include ResourcesHolder
   
    field   :Type,                  :Type => Name, :Default => :Page, :Required => true
    field   :Parent,                :Type => Dictionary, :Required => true
    field   :LastModified,          :Type => String, :Version => "1.3"
    field   :Resources,             :Type => Dictionary, :Required => true 
    field   :MediaBox,              :Type => Array, :Default => Rectangle[ :llx => 0, :lly => 0, :urx => 795, :ury => 842 ], :Required => true
    field   :CropBox,               :Type => Array
    field   :BleedBox,              :Type => Array, :Version => "1.3"
    field   :TrimBox,               :Type => Array, :Version => "1.3"
    field   :ArtBox,                :Type => Array, :Version => "1.3"
    field   :BoxColorInfo,          :Type => Dictionary, :Version => "1.4"
    field   :Contents,              :Type => [ Stream, Array ]
    field   :Rotate,                :Type => Integer, :Default => 0
    field   :Group,                 :Type => Dictionary, :Version => "1.4"
    field   :Thumb,                 :Type => Stream
    field   :B,                     :Type => Array, :Version => "1.1"
    field   :Dur,                   :Type => Integer, :Version => "1.1"
    field   :Trans,                 :Type => Dictionary, :Version => "1.1"
    field   :Annots,                :Type => Array
    field   :AA,                    :Type => Dictionary, :Version => "1.2"
    field   :Metadata,              :Type => Stream, :Version => "1.4"
    field   :PieceInfo,             :Type => Dictionary, :Version => "1.2"
    field   :StructParents,         :Type => Integer, :Version => "1.3"
    field   :ID,                    :Type => String
    field   :PZ,                    :Type => Number
    field   :SeparationInfo,        :Type => Dictionary, :Version => "1.3"
    field   :Tabs,                  :Type => Name, :Version => "1.5"
    field   :TemplateAssociated,    :Type => Name, :Version => "1.5"
    field   :PresSteps,             :Type => Dictionary, :Version => "1.5"
    field   :UserUnit,              :Type => Number, :Default => 1.0, :Version => "1.6"
    field   :VP,                    :Type => Dictionary, :Version => "1.6"

    def initialize(hash = {})
      super(hash)
      
      set_indirect(true)
    end

    def render(engine) #:nodoc:
      contents = self.Contents
      return unless contents.is_a? Stream
      
      unless contents.is_a? ContentStream
        contents = ContentStream.new(contents.data)
      end

      contents.render(engine)
    end

    def pre_build
      self.Resources = Resources.new.pre_build unless self.has_key?(:Resources)

      super
    end

    #
    # Add an Annotation to the Page.
    #
    def add_annot(*annotations)
      unless annotations.all?{|annot| annot.is_a?(Annotation) or annot.is_a?(Reference)}
        raise TypeError, "Only Annotation objects must be passed."
      end
      
      self.Annots ||= []

      annotations.each do |annot| 
        annot.solve[:P] = self if is_indirect?
        self.Annots << annot 
      end
    end

    #
    # Iterate through each Annotation of the Page.
    #
    def each_annot(&b)
      annots = self.Annots
      return unless annots.is_a?(Array)

      annots.each do |annot|
        b.call(annot.solve) 
      end
    end

    #
    # Returns the array of Annotation objects of the Page.
    #
    def annotations
      annots = self.Annots
      return [] unless annots.is_a?(Array)
      
      annots.map{|annot| annot.solve} 
    end

    #
    # Embed a SWF Flash application in the page.
    #
    def add_flash_application(swfspec, params = {})
      options =
      {
        :windowed => false,
        :transparent => false,
        :navigation_pane => false,
        :toolbar => false,
        :pass_context_click => false,
        :activation => Annotation::RichMedia::Activation::PAGE_OPEN,
        :deactivation => Annotation::RichMedia::Deactivation::PAGE_CLOSE,
        :flash_vars => nil
      }
      options.update(params)
    
      annot = create_richmedia(:Flash, swfspec, options)
      add_annot(annot)

      annot
    end

    #
    # Will execute an action when the page is opened.
    #
    def onOpen(action)
      unless action.is_a?(Action) or action.is_a?(Reference)
        raise TypeError, "An Action object must be passed."
      end
      
      self.AA ||= PageAdditionalActions.new
      self.AA.O = action
      
      self
    end
    
    #
    # Will execute an action when the page is closed.
    #
    def onClose(action)
      unless action.is_a?(Action) or action.is_a?(Reference)
        raise TypeError, "An Action object must be passed."
      end
      
      self.AA ||= PageAdditionalActions.new
      self.AA.C = action

      self
    end

    #
    # Will execute an action when navigating forward from this page.
    #
    def onNavigateForward(action) #:nodoc:
      unless action.is_a?(Action) or action.is_a?(Reference)
        raise TypeError, "An Action object must be passed."
      end
      
      self.PresSteps ||= NavigationNode.new
      self.PresSteps.NA = action

      self
    end

    #
    # Will execute an action when navigating backward from this page.
    #
    def onNavigateBackward(action) #:nodoc:
      unless action.is_a?(Action) or action.is_a?(Reference)
        raise TypeError, "An Action object must be passed."
      end
      
      self.PresSteps ||= NavigationNode.new
      self.PresSteps.PA = action
    
      self
    end

    private

    def create_richmedia(type, content, params) #:nodoc:
      content.set_indirect(true)
      richmedia = Annotation::RichMedia.new.set_indirect(true)

      rminstance = Annotation::RichMedia::Instance.new.set_indirect(true)
      rmparams = rminstance.Params = Annotation::RichMedia::Parameters.new
      rmparams.Binding = Annotation::RichMedia::Parameters::Binding::BACKGROUND
      rmparams.FlashVars = params[:flash_vars]
      rminstance.Asset = content

      rmconfig = Annotation::RichMedia::Configuration.new.set_indirect(true)
      rmconfig.Instances = [ rminstance ]
      rmconfig.Subtype = type

      rmcontent = richmedia.RichMediaContent = Annotation::RichMedia::Content.new.set_indirect(true)
      rmcontent.Assets = NameTreeNode.new
      rmcontent.Assets.Names = NameLeaf.new(content.F.value => content)

      rmcontent.Configurations = [ rmconfig ]

      rmsettings = richmedia.RichMediaSettings = Annotation::RichMedia::Settings.new
      rmactivation = rmsettings.Activation = Annotation::RichMedia::Activation.new
      rmactivation.Condition = params[:activation]
      rmactivation.Configuration = rmconfig
      rmactivation.Animation = Annotation::RichMedia::Animation.new(:PlayCount => -1, :Subtype => :Linear, :Speed => 1.0)
      rmpres = rmactivation.Presentation = Annotation::RichMedia::Presentation.new
      rmpres.Style = Annotation::RichMedia::Presentation::WINDOWED if params[:windowed]
      rmpres.Transparent = params[:transparent]
      rmpres.NavigationPane = params[:navigation_pane]
      rmpres.Toolbar = params[:toolbar]
      rmpres.PassContextClick = params[:pass_context_click]

      rmdeactivation = rmsettings.Deactivation = Annotation::RichMedia::Deactivation.new
      rmdeactivation.Condition = params[:deactivation]

      richmedia
    end
    
  end
  
  #
  # Class representing additional actions which can be associated to a Page.
  #
  class PageAdditionalActions < Dictionary
    include StandardObject
   
    field   :O,   :Type => Dictionary, :Version => "1.2" # Page Open
    field   :C,   :Type => Dictionary, :Version => "1.2" # Page Close
  end

  #
  # Class representing a navigation node associated to a Page.
  #
  class NavigationNode < Dictionary
    include StandardObject

    field   :Type,    :Type => Name, :Default => :NavNode
    field   :NA,      :Type => Dictionary # Next action
    field   :PA,      :Type => Dictionary # Prev action
    field   :Next,    :Type => Dictionary 
    field   :Prev,    :Type => Dictionary 
    field   :Dur,     :Type => Number
  end
  
end
