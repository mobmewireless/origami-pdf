=begin

= File
	treeview.rb

= Info
	This file is part of PDF Walker, a graphical PDF file browser 
	Copyright (C) 2010	Guillaume Delugré <guillaume@security-labs.org>
	All right reserved.
	
  PDF Walker is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  PDF Walker is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with PDF Walker.  If not, see <http://www.gnu.org/licenses/>.

=end

module PDFWalker

  class Walker < Window
    
    private
    
    def create_treeview
      
      @treeview = PDFTree.new(self).set_headers_visible(false)
                                       
      colcontent = Gtk::TreeViewColumn.new("Names", 
        Gtk::CellRendererText.new.set_foreground_set(true).set_background_set(true), 
                                       :text => PDFTree::TEXTCOL,
                                       :weight => PDFTree::WEIGHTCOL,
                                       :style => PDFTree::STYLECOL,
                                       :foreground => PDFTree::FGCOL,
                                       :background => PDFTree::BGCOL
      )
      
      @treeview.append_column(colcontent)
      
    end
    
  end
  
  class PDFTree < TreeView
    
    include Popable
	  
    OBJCOL = 0
    TEXTCOL = 1
    WEIGHTCOL = 2
    STYLECOL = 3
    FGCOL = 4
    BGCOL = 5
    
    @@appearance = Hash.new(:Weight => Pango::WEIGHT_NORMAL, :Style => Pango::STYLE_NORMAL)
    
    attr_reader :parent
    
    def initialize(parent)
      
      @parent = parent
      
      reset_appearance
      
      @treestore = TreeStore.new(Object::Object, String, Pango::FontDescription::Weight, Pango::FontDescription::Style, String, String)
      super(@treestore)
      
      signal_connect('cursor-changed') {
        iter = selection.selected
        if iter
          obj = @treestore.get_value(iter, OBJCOL)
          
          if obj.is_a?(Stream) and iter.n_children == 1
           
            # Processing with an XRef or Object Stream
            if obj.is_a?(ObjectStream)
              obj.each { |embeddedobj|
                load_object(iter, embeddedobj)
              }

            elsif obj.is_a?(XRefStream)
              obj.each { |xref|
                load_xrefstm(iter, xref)
              }
            end
          end

          parent.hexview.load(obj)
          parent.objectview.load(obj)
        end
      }
      
      signal_connect('row-activated') { |tree, path, column|
        if selection.selected
          obj = @treestore.get_value(selection.selected, OBJCOL)
          
          if row_expanded?(path)
            collapse_row(path)
          else
            expand_row(path, false)
          end
          
          goto(obj.solve) if obj.is_a?(Origami::Reference)
        end
      }
      
      add_events(Gdk::Event::BUTTON_PRESS_MASK)
      signal_connect('button_press_event') { |widget, event|
        if event.button == 3 && parent.opened
          path = get_path(event.x,event.y).first
          set_cursor(path, nil, false)
          
          obj = @treestore.get_value(@treestore.get_iter(path), OBJCOL)
          popup_menu(obj, event, path)
        end
      }
      
    end
    
    def clear
      @treestore.clear
    end
    
    def goto(obj)
      
      if obj.is_a?(TreePath)
        set_cursor(obj, nil, false)
      else
        if obj.is_a?(Name) and obj.parent.is_a?(Dictionary) and obj.parent.has_key?(obj)
          obj = obj.parent[obj]
        elsif obj.is_a?(Reference)
          obj = obj.solve
        end

        @treestore.each { |model, path, iter|
          current_obj = @treestore.get_value(iter, OBJCOL)
          
          if current_obj.is_a?(ObjectStream) and obj.parent.equal?(current_obj)
            current_obj.each { |embeddedobj|
              load_object(iter, embeddedobj)
            }
            next
          end

          if obj.equal?(current_obj)
            expand_to_path(path) unless row_expanded?(path) 
            
            if cursor.first then @parent.explorer_history << cursor.first end
            set_cursor(path, nil, false)
            
            return
          end
        }
        
        @parent.error("Object not found : #{obj}")
      end
      
    end

    def highlight(obj, color)
      if obj.is_a?(Name) and obj.parent.is_a?(Dictionary) and obj.parent.has_key?(obj)
        obj = obj.parent[obj]
      end

      @treestore.each { |model, path, iter|
        current_obj = @treestore.get_value(iter, OBJCOL)
        
        if obj.equal?(current_obj)
          @treestore.set_value(iter, BGCOL, color)
          expand_to_path(path) unless row_expanded?(path)
          return
        end
      }
      
      @parent.error("Object not found : #{obj}")
    end
    
    def load(pdf)
      
      if pdf
        self.clear
        
        begin
          #
          # Create root entry
          #
          root = @treestore.append(nil)
          @treestore.set_value(root, OBJCOL, pdf)
        
          set_node(root, :Filename, @parent.filename)
        
          #
          # Create header entry
          #
          header = @treestore.append(root)
          @treestore.set_value(header, OBJCOL, pdf.header)
        
          set_node(header, :Header, "Header (version #{pdf.header.majorversion}.#{pdf.header.minorversion})")
        
          no = 1
          pdf.revisions.each { |revision|
        
            load_revision(root, no, revision)
            no = no + 1
        
          }
        
          set_model(@treestore)
        
        ensure
          expand(@treestore.iter_first, 3)
          set_cursor(@treestore.iter_first.path, nil, false)
        end
      end
    
    end
  
    private
    
    def expand(row, depth)
      
      if row and depth != 0
        
        loop do
          expand_row(row.path, false)
          expand(row.first_child, depth - 1)
          
          break if not row.next!
        end
        
      end
      
    end
    
    def load_revision(root, no, revision)
    
      revroot = @treestore.append(root)
      @treestore.set_value(revroot, OBJCOL, revision)
      
      set_node(revroot, :Revision, "Revision #{no}")
      
      load_body(revroot, revision.body.values)
      
      load_xrefs(revroot, revision.xreftable)
      
      load_trailer(revroot, revision.trailer)
      
    end
  
    def load_body(rev, body)
      
      bodyroot = @treestore.append(rev)
      @treestore.set_value(bodyroot, OBJCOL, body)
      
      set_node(bodyroot, :Body, "Body")
      
      body.sort_by{|obj| obj.file_offset}.each { |object|
        begin
          load_object(bodyroot, object)
        rescue Exception => e
          msg = "#{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
          
          #@parent.error(msg)
          next
        end
      }
    
    end
  
    def load_object(container, object, name = nil)
        
      obj = @treestore.append(container)
      @treestore.set_value(obj, OBJCOL, object)
      
      type = object.real_type.to_s.split('::').last.to_sym
      
      if name.nil?
        name = 
          case object
            when Origami::String
              '"' + object.to_utf8 + '"'
            when Origami::Number, Name
              object.value.to_s
            else
              object.type.to_s
          end
      end

      set_node(obj, type, name)
      
      if object.is_a? Origami::Array
        object.each { |subobject|
          load_object(obj, subobject)
        }
      elsif object.is_a? Origami::Dictionary
        object.each_key { |subkey|
          load_object(obj, object[subkey.value], subkey.value.to_s)
        }
      elsif object.is_a? Origami::Stream
        load_object(obj, object.dictionary, "Stream Dictionary")
      end
    
    end

    def load_xrefstm(stm, embxref)
      
      xref = @treestore.append(stm)
      @treestore.set_value(xref, OBJCOL, embxref)

      if embxref.is_a?(XRef)
        set_node(xref, :XRef, embxref.to_s.chomp)
      else
        set_node(xref, :XRef, "xref to ObjectStream #{embxref.objstmno}, object index #{embxref.index}")
      end

    end
    
    def load_xrefs(rev, table)
      
      if table
        
        section = @treestore.append(rev)
        @treestore.set_value(section, OBJCOL, table)
        
        set_node(section, :XRefSection, "XRef section")
        
        table.each { |subtable|
        
          subsection = @treestore.append(section)
          @treestore.set_value(subsection, OBJCOL, subtable)
          
          set_node(subsection, :XRefSubSection, "#{subtable.range.begin} #{subtable.range.end - subtable.range.begin + 1}")
          
          subtable.each { |entry|
            
            xref = @treestore.append(subsection)
            @treestore.set_value(xref, OBJCOL, entry)
            
            set_node(xref, :XRef, entry.to_s.chomp)
            
          }
        
        }
        
      end
      
    end
      
    def load_trailer(rev, trailer)
      
      trailerroot = @treestore.append(rev)
      @treestore.set_value(trailerroot, OBJCOL, trailer)
      
      set_node(trailerroot, :Trailer, "Trailer")
      
      unless trailer.dictionary.nil?
        load_object(trailerroot, trailer.dictionary)
      end
      
    end
    
    def reset_appearance
      
      @@appearance[:Filename] = {:Weight => Pango::WEIGHT_BOLD, :Style => Pango::STYLE_NORMAL}
      @@appearance[:Header] = {:Color => "darkgreen", :Weight => Pango::WEIGHT_BOLD, :Style => Pango::STYLE_NORMAL}
      @@appearance[:Revision] = {:Color => "blue", :Weight => Pango::WEIGHT_BOLD, :Style => Pango::STYLE_NORMAL}
      @@appearance[:Body] = {:Color => "purple", :Weight => Pango::WEIGHT_BOLD, :Style => Pango::STYLE_NORMAL}
      @@appearance[:XRefSection] = {:Color => "purple", :Weight => Pango::WEIGHT_BOLD, :Style => Pango::STYLE_NORMAL}
      @@appearance[:XRefSubSection] = {:Color => "brown", :Weight => Pango::WEIGHT_BOLD, :Style => Pango::STYLE_NORMAL}
      @@appearance[:XRef] = {:Color => "gray20", :Weight => Pango::WEIGHT_BOLD, :Style => Pango::STYLE_NORMAL}
      @@appearance[:Trailer] = {:Color => "purple", :Weight => Pango::WEIGHT_BOLD, :Style => Pango::STYLE_NORMAL}
      @@appearance[:StartXref] = {:Weight => Pango::WEIGHT_BOLD, :Style => Pango::STYLE_NORMAL}
      @@appearance[:String] = {:Color => "red", :Weight => Pango::WEIGHT_NORMAL, :Style => Pango::STYLE_ITALIC}
      @@appearance[:Name] = {:Color => "gray", :Weight => Pango::WEIGHT_NORMAL, :Style => Pango::STYLE_ITALIC}
      @@appearance[:Number] = {:Color => "orange", :Weight => Pango::WEIGHT_NORMAL, :Style => Pango::STYLE_NORMAL}
      @@appearance[:Dictionary] = {:Color => "brown", :Weight => Pango::WEIGHT_BOLD, :Style => Pango::STYLE_NORMAL}
      @@appearance[:Stream] = {:Color => "darkcyan", :Weight => Pango::WEIGHT_BOLD, :Style => Pango::STYLE_NORMAL}
      @@appearance[:StreamData] = {:Color => "darkcyan", :Weight => Pango::WEIGHT_NORMAL, :Style => Pango::STYLE_OBLIQUE}
      @@appearance[:Array] = {:Color => "darkgreen", :Weight => Pango::WEIGHT_BOLD, :Style => Pango::STYLE_NORMAL}
      @@appearance[:Reference] = {:Weight => Pango::WEIGHT_NORMAL, :Style => Pango::STYLE_OBLIQUE}
      @@appearance[:Boolean] = {:Color => "deeppink", :Weight => Pango::WEIGHT_NORMAL, :Style => Pango::STYLE_NORMAL}
      
    end
    
    def get_object_appearance(type)
      @@appearance[type]
    end
    
    def set_node(node, type, text)
      
      @treestore.set_value(node, TEXTCOL, text)
      
      app = get_object_appearance(type)
      @treestore.set_value(node, WEIGHTCOL, app[:Weight])
      @treestore.set_value(node, STYLECOL, app[:Style])
      @treestore.set_value(node, FGCOL, app[:Color])
      
    end
  
  end

end
