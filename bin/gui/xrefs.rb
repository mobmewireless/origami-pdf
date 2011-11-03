=begin

= File
	xrefs.rb

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

require 'origami'
include Origami

module PDFWalker

  class Walker < Window
    
    def show_xrefs(target)
      XrefsDialog.new(self, target)
    end

  end

  class XrefsDialog < Dialog
  
    OBJCOL = 0
    TEXTCOL = 1

    def initialize(parent, target)
      
      super("Xrefs to #{target.reference}", parent, Dialog::MODAL, [Stock::CLOSE, Dialog::RESPONSE_NONE])
      @parent = parent

      @list = ListStore.new(Object, String)
      @view = TreeView.new(@list)

      column = Gtk::TreeViewColumn.new("Objects", Gtk::CellRendererText.new, :text => TEXTCOL)
      @view.append_column(column)

      target.xrefs.each { |obj|
        str = obj.class.to_s
        iter = @list.append
        @list.set_value(iter, OBJCOL, obj)
        @list.set_value(iter, TEXTCOL, str)
      }

      @view.signal_connect("row_activated") { |tree, path, column|
        if @view.selection.selected
          from = @list.get_value(@view.selection.selected, OBJCOL)
          @parent.treeview.goto(from) 
        end
      }

      scroll = ScrolledWindow.new.set_policy(POLICY_NEVER, POLICY_AUTOMATIC)
      scroll.add(@view)
      vbox.add(scroll)

      signal_connect('response') { destroy }  
      show_all
    end
    
  end

end
