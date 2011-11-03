#!/usr/bin/env ruby

=begin

= File
	walker.rb

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

begin
  require 'gtk2'
rescue LoadError
  abort('Error: you need to install ruby-gtk2 to run this application')
end
include Gtk

begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../../lib"
  $: << ORIGAMIDIR
  require 'origami'
end

require 'gui/menu'
require 'gui/about'
require 'gui/file'
require 'gui/hexview'
require 'gui/treeview'
require 'gui/textview'
require 'gui/imgview'
require 'gui/config'
require 'gui/properties'
require 'gui/xrefs'
require 'gui/signing'

module PDFWalker  #:nodoc:all

  class Walker < Window
    
    attr_reader :treeview, :hexview, :objectview
    attr_reader :explorer_history
    attr_reader :config
    attr_reader :filename

    def self.start(file = nil)
      Gtk.init
      Walker.new(file)
      Gtk.main
    end

    def initialize(target_file = nil)
      super("PDF Walker")
      
      @config = Walker::Config.new
     
      @last_search_result = []
      @last_search =
      {
        :expr => "",
        :regexp => false,
        :type => :body
      }

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
      
      set_default_size(self.screen.width * 0.5, self.screen.height * 0.5)
      #maximize
      show_all
      
      open(target_file)
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

    def search
      dialog = Gtk::Dialog.new("Search...",
        self,
        Gtk::Dialog::MODAL | Gtk::Dialog::DESTROY_WITH_PARENT,
        [Gtk::Stock::FIND, Gtk::Dialog::RESPONSE_OK],
        [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL]
      )

      entry = Gtk::Entry.new
      entry.signal_connect('activate') { dialog.response(Gtk::Dialog::RESPONSE_OK) }
      entry.text = @last_search[:expr]

      button_bydata = Gtk::RadioButton.new("In object body")
      button_byname = Gtk::RadioButton.new(button_bydata, "In object name")
      button_regexp = Gtk::CheckButton.new("Regular expression")

      button_bydata.set_active(true) if @last_search[:type] == :body
      button_byname.set_active(true) if @last_search[:type] == :name
      button_regexp.set_active(@last_search[:regexp])

      hbox = HBox.new
      hbox.pack_start Gtk::Label.new("Search for expression ")
      hbox.pack_start entry

      dialog.vbox.pack_start(hbox)
      dialog.vbox.pack_start(button_bydata)
      dialog.vbox.pack_start(button_byname)
      dialog.vbox.pack_end(button_regexp)

      dialog.signal_connect('response') do |dlg, response|
        if response == Gtk::Dialog::RESPONSE_OK
          search =
          {
            :expr => entry.text,
            :regexp => button_regexp.active?,
            :type => button_byname.active? ? :name : :body
          }

          if search == @last_search
            @last_search_result.push @last_search_result.shift
            results = @last_search_result
          else
            expr = search[:regexp] ? Regexp.new(search[:expr]) : search[:expr]
            
            results = 
            if search[:type] == :body
              @opened.grep(expr)
            else
              @opened.ls(expr)
            end
            @last_search = search
          end

          if results.empty?
            error("No result found.")
          else
            if results != @last_search_result
              @last_search_result.each do |obj| @treeview.highlight(obj, nil) end
              results.each do |obj| @treeview.highlight(obj, "lightpink") end

              @last_search_result = results
            end

            @treeview.goto(results.first)
          end
        else
          dialog.destroy
        end
      end

      dialog.show_all
    end

    def goto_catalog
      @treeview.goto(@opened.Catalog.reference)
    end

    def goto_object
      dialog = Gtk::Dialog.new("Jump to object...",
        self,
        Gtk::Dialog::MODAL | Gtk::Dialog::DESTROY_WITH_PARENT,
        [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK],
        [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL]
      )

      entry = Gtk::Entry.new
      entry.signal_connect('activate') { dialog.response(Gtk::Dialog::RESPONSE_OK) }

      dialog.vbox.pack_start Gtk::Label.new("Object number: ")
      dialog.vbox.pack_start entry
      dialog.show_all

      no = 0
      dialog.run do |response|
        if response == Gtk::Dialog::RESPONSE_OK
          no = entry.text.to_i
        end

        dialog.destroy
      end

      if no > 0
        obj = @opened[no]

        if obj.nil?
          error("Object #{no} not found.")
        else
          @treeview.goto(obj)
        end
      end
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
