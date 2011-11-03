=begin

= File
	file.rb

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
    
    attr_reader :opened
    attr_reader :explore_history
    
    def close
      
      @opened = nil
      @filename = ''
      @explorer_history.clear
      
      @treeview.clear
      @objectview.clear
      @hexview.clear
      
      [ 
        @file_menu_close, @file_menu_saveas, @file_menu_serialize, @file_menu_refresh, 
        @document_menu_search,
        @document_menu_gotocatalog, @document_menu_gotopage, @document_menu_gotorev, @document_menu_gotoobj,
        @document_menu_properties, @document_menu_sign, @document_menu_ur 
      ].each do |menu| 
        menu.sensitive = false
      end
      
      @statusbar.pop(@main_context)
      
      GC.start
    end
    
    def open(filename = nil)
      
      dialog = Gtk::FileChooserDialog.new("Open PDF File",
                                           self,
                                           FileChooser::ACTION_OPEN,
                                           nil,
                                           [Stock::CANCEL, Dialog::RESPONSE_CANCEL],
                                           [Stock::OPEN, Dialog::RESPONSE_ACCEPT])
      
      last_file = @config.recent_files.first
      unless last_file.nil?
        last_folder = last_file[0..last_file.size - File.basename(last_file).size - 1]
        dialog.set_current_folder(last_folder) if File.directory?(last_folder)
      end
    
      dialog.filter = FileFilter.new.add_pattern("*.acrodata").add_pattern("*.pdf").add_pattern("*.fdf")
      
      if filename or dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
        
        create_progressbar
        
        filename ||= dialog.filename
        dialog.destroy
        
        begin
          
          if @help_menu_profile.active?
            require 'ruby-prof'
            RubyProf.start 
          end
          
          target = parsefile(filename)
          
          if @help_menu_profile.active?
            result = RubyProf.stop
            txtprinter = RubyProf::FlatPrinter.new(result)
            htmlprinter = RubyProf::GraphHtmlPrinter.new(result)
            txtprinter.print(File.new("#{@config.profile_output_dir}/#{File.basename(filename)}.log", "w"))
            htmlprinter.print(File.new("#{@config.profile_output_dir}/#{File.basename(filename)}.log.html", "w"))
          end
          
          if target
            close if @opened
            @opened = target
            @filename = filename
            
            @config.last_opened_file(filename)
            @config.save
            update_recent_menu
            
            @last_search_result = []
            @last_search =
            {
              :expr => "",
              :regexp => false,
              :type => :body
            }

            self.reload
            
            [ 
              @file_menu_close, @file_menu_saveas, @file_menu_serialize, @file_menu_refresh, 
              @document_menu_search, 
              @document_menu_gotocatalog, @document_menu_gotopage, @document_menu_gotorev, @document_menu_gotoobj,
              @document_menu_properties, @document_menu_sign, @document_menu_ur 
            ].each do |menu| 
              menu.sensitive = true 
            end
            
            @explorer_history.clear
            
            @statusbar.push(@main_context, "Viewing #{filename}")

            if @opened.is_a?(PDF)
              pagemenu = Menu.new
              @document_menu_gotopage.remove_submenu
              page_index = 1
              @opened.pages.each do |page|
                pagemenu.append(item = MenuItem.new(page_index.to_s).show)
                item.signal_connect("activate") do @treeview.goto(page)  end
                page_index = page_index + 1
              end
              @document_menu_gotopage.set_submenu(pagemenu)

              revmenu = Menu.new
              @document_menu_gotorev.remove_submenu
              rev_index = 1
              @opened.revisions.each do |rev|
                revmenu.append(item = MenuItem.new(rev_index.to_s).show)
                item.signal_connect("activate") do @treeview.goto(rev)  end
                rev_index = rev_index + 1
              end
              @document_menu_gotorev.set_submenu(revmenu)

              goto_catalog
            end
          end
          
        rescue Exception => e
          error("Error while parsing file.\n#{e} (#{e.class})\n" + e.backtrace.join("\n"))
        end
        
        close_progressbar
        self.activate_focus
        
      else
        dialog.destroy
      end
      
    end
    
    def deserialize
      
     dialog = Gtk::FileChooserDialog.new("Open dump file",
                                           self,
                                           FileChooser::ACTION_OPEN,
                                           nil,
                                           [Stock::CANCEL, Dialog::RESPONSE_CANCEL],
                                           [Stock::OPEN, Dialog::RESPONSE_ACCEPT])
      
      dialog.current_folder = "#{Dir.pwd}/dumps"
      dialog.filter = FileFilter.new.add_pattern("*.gz")
      
      if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
        
        if @opened then close end
        filename = dialog.filename
        
        begin
          
          @opened = PDF.deserialize(filename)
          
          self.reload
          
          [ @file_menu_close, @file_menu_saveas, @file_menu_serialize, @file_menu_refresh, 
            @document_menu_properties, @document_menu_sign, @document_menu_ur ].each do |menu| 
            menu.sensitive = true 
          end
          
          @explorer_history.clear
          
          @statusbar.push(@main_context, "Viewing dump of #{filename}")
          
        rescue Exception => e
          error("This file cannot be loaded.\n#{e} (#{e.class})")
        end

      end
      
      dialog.destroy
      
    end
    
    def serialize
      
      dialog = Gtk::FileChooserDialog.new("Save dump file",
         self,
         Gtk::FileChooser::ACTION_SAVE,
         nil,
         [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
         [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_ACCEPT]
      )
      
      dialog.do_overwrite_confirmation = true
      dialog.current_folder = "#{Dir.pwd}/dumps"
      dialog.current_name = "#{File.basename(@filename)}.dmp.gz"
      dialog.filter = FileFilter.new.add_pattern("*.gz")
      
      if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
        @opened.serialize(dialog.filename)
      end
      
      dialog.destroy
    end
    
    def save_data(caption, data, filename = "")
      
      dialog = Gtk::FileChooserDialog.new(caption,
         self,
         Gtk::FileChooser::ACTION_SAVE,
         nil,
         [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
         [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_ACCEPT]
      )
      
      dialog.do_overwrite_confirmation = true
      dialog.current_name = File.basename(filename)
      dialog.filter = FileFilter.new.add_pattern("*.*")
      
      if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
        fd = File.open(dialog.filename, "w").binmode
          fd << data
        fd.close
      end
      
      dialog.destroy
    end
    
    def save
      
      dialog = Gtk::FileChooserDialog.new("Save PDF file",
         self,
         Gtk::FileChooser::ACTION_SAVE,
         nil,
         [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
         [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_ACCEPT]
      )
      
      dialog.filter = FileFilter.new.add_pattern("*.acrodata").add_pattern("*.pdf").add_pattern("*.fdf")
        
      folder = @filename[0..@filename.size - File.basename(@filename).size - 1]
      dialog.set_current_folder(folder)
      
      if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
        @opened.save(dialog.filename)
      end
      
      dialog.destroy
    end

    def save_dot
    
     dialog = Gtk::FileChooserDialog.new("Save dot file",
         self,
         Gtk::FileChooser::ACTION_SAVE,
         nil,
         [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
         [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_ACCEPT]
      )
      
      dialog.filter = FileFilter.new.add_pattern("*.dot")
      
      folder = @filename[0..@filename.size - File.basename(@filename).size - 1]
      dialog.set_current_folder(folder)
      
      if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
        @opened.export_to_graph(dialog.filename)
      end
      
      dialog.destroy
    end
    
    def save_graphml
      
     dialog = Gtk::FileChooserDialog.new("Save GraphML file",
         self,
         Gtk::FileChooser::ACTION_SAVE,
         nil,
         [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
         [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_ACCEPT]
      )
      
      dialog.filter = FileFilter.new.add_pattern("*.graphml")
      
      folder = @filename[0..@filename.size - File.basename(@filename).size - 1]
      dialog.set_current_folder(folder)
      
      if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
        @opened.export_to_graphml(dialog.filename)
      end
      
      dialog.destroy
    end

    private

    def parsefile(filename)
      update_bar = lambda { |obj|
        if @progressbar then @progressbar.pulse end
        while (Gtk.events_pending?) do Gtk.main_iteration end
      }

      prompt_passwd = lambda {
        passwd = ""

        dialog = Gtk::Dialog.new(
          "This document is encrypted",
          nil,
          Gtk::Dialog::MODAL,
          [ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ],
          [ Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL ]
        )

        dialog.set_default_response(Gtk::Dialog::RESPONSE_OK)

        label = Gtk::Label.new("Please enter password:")
        entry = Gtk::Entry.new
        entry.signal_connect('activate') {
          dialog.response(Gtk::Dialog::RESPONSE_OK)
        }

        dialog.vbox.add(label)
        dialog.vbox.add(entry)
        dialog.show_all

        dialog.run do |response|
          if response == Gtk::Dialog::RESPONSE_OK
            passwd = entry.text
          end
        end
                            
        dialog.destroy

        return passwd
      }
      
      PDF.read(filename, 
        :verbosity => Parser::VERBOSE_INSANE, 
        :ignoreerrors => false, 
        :callback => update_bar,
        :prompt_password => prompt_passwd
      )
    end
    
    def create_progressbar
      @progresswin = Dialog.new("Parsing file...", self, Dialog::MODAL)
      @progresswin.vbox.add(@progressbar = ProgressBar.new.set_pulse_step(0.05))
      @progresswin.show_all
    end
    
    def close_progressbar
      @progresswin.close
    end
  end

end
