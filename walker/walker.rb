#!/usr/bin/env ruby

=begin

= File
	walker.rb

= Info
	This file is part of Origami, PDF manipulation framework for Ruby
	Copyright (C) 2009	Guillaume Delugré <guillaume@security-labs.org>
	All right reserved.
	
  Origami is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Origami is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Origami.  If not, see <http://www.gnu.org/licenses/>.

=end

require 'gtk2'
include Gtk

if __FILE__ == $0
  $: << File.dirname($0)
  $: << "#{File.dirname($0)}/../parser"
end

require 'menu.rb'
require 'about.rb'
require 'io.rb'
require 'hexview.rb'
require 'treeview.rb'
require 'textview.rb'
require 'config.rb'
require 'properties.rb'
require 'xrefs.rb'
require 'signing.rb'

module PDFWalker  #:nodoc:all

  class Walker < Window
    
    attr_reader :treeview, :hexview, :objectview
    attr_reader :explorer_history
    attr_reader :config

    def self.start
      Gtk.init
      Walker.new
      Gtk.main
    end

    def initialize
      
      super("PDF Walker")
      
      @config = Walker::Config.new
      
      @explorer_history = Array.new
      
      signal_connect('destroy') {
        @config.save
        Gtk.main_quit
      }
      
      add_events(Gdk::Event::KEY_RELEASE_MASK)
      signal_connect('key_release_event') { |w, event|
        
        if event.keyval == Gdk::Keyval::GDK_F1 then about
        elsif event.keyval == Gdk::Keyval::GDK_Escape && @opened && ! @explorer_history.empty?
          @treeview.goto(@explorer_history.pop)
        end
      
      }
      
      create_menus
      create_treeview
      create_hexview
      create_objectview
      create_panels
      create_statusbar
      
      @vbox = VBox.new
      @vbox.pack_start(@menu, false, false)
      @vbox.pack_start(@hpaned)
      @vbox.pack_end(@statusbar, false, false)
      
      add @vbox
      
      # set_icon("icons/gnome-pdf.png")
      
      set_default_size(self.screen.width * 0.5, self.screen.height * 0.5)
      maximize
      show_all
      
      open
    end
    
    def error(msg)
      
      dialog = Gtk::MessageDialog.new(self, 
                                      Gtk::Dialog::DESTROY_WITH_PARENT,
                                      Gtk::MessageDialog::ERROR,
                                      Gtk::MessageDialog::BUTTONS_CLOSE,
                                      msg)
      dialog.run
      dialog.destroy
      
    end
    
    def reload
      @treeview.load(@opened) if @opened
    end

    def goto_catalog
      @treeview.goto(@opened.Catalog)
    end
    
    private
    
    def create_panels
      
      @hpaned = HPaned.new
      
      @treepanel = ScrolledWindow.new.set_policy(POLICY_AUTOMATIC, POLICY_AUTOMATIC)
      @treepanel.add @treeview
      
      @vpaned = VPaned.new
      @vpaned.pack1(@objectview, true, false)
      @vpaned.pack2(@hexview, true, false)
      
      @hpaned.pack1(@treepanel, true, false)
      @hpaned.pack2(@vpaned, true, false)
      
    end
    
    def create_statusbar
      
      @statusbar = Statusbar.new
      
      @main_context = @statusbar.get_context_id 'Main'
      @statusbar.push(@main_context, 'No file selected')
      
    end
    
  end

end

if __FILE__ == $0
  PDFWalker::Walker.start
end
