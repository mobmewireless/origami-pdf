=begin

= File
	properties.rb

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

require 'iconv'
require 'digest/md5'

module PDFWalker

  class Walker < Window
    
    def display_file_properties
      if @opened
        prop = Properties.new(self, @opened)
      end
    end
    
    class Properties < Dialog
      
      @@acrobat_versions =
      {
        1.0 => "1.x",
        1.1 => "2.x",
        1.2 => "3.x",
        1.3 => "4.x",
        1.4 => "5.x",
        1.5 => "6.x",
        1.6 => "7.x",
        1.7 => "8.x / 9.x / 10.x"
      }
      
      def initialize(parent, pdf)
        super("Document properties", parent, Dialog::MODAL, [Stock::CLOSE, Dialog::RESPONSE_NONE])
        
        docframe = Frame.new(" File properties ")
        stat = File.stat(parent.filename)
        
        if RUBY_VERSION < '1.9'
          require 'iconv'
          i = Iconv.new("UTF-8//IGNORE//TRANSLIT", "ISO-8859-1")

          creation_date = i.iconv(stat.ctime.to_s)
          last_modified = i.iconv(stat.mtime.to_s)
          fd = File.open(parent.filename, 'rb')
          md5sum = Digest::MD5.hexdigest(fd.read)
          fd.close
          i.close
        else
          creation_date = stat.ctime.to_s.encode("utf-8", :invalid => :replace, :undef => :replace)
          last_modified = stat.mtime.to_s.encode("utf-8", :invalid => :replace, :undef => :replace)
          md5sum = Digest::MD5.hexdigest(File.binread(parent.filename))
        end
        
        labels = 
        [ 
          [ "Filename:", parent.filename ],
          [ "File size:", "#{File.size(parent.filename)} bytes" ],
          [ "MD5:", md5sum ],
          [ "Read-only:", "#{not stat.writable?}" ],
          [ "Creation date:", creation_date ],
          [ "Last modified:", last_modified ]
        ]

        doctable = Table.new(labels.size + 1, 3)
        
        row = 0
        labels.each do |name, value|
          
          doctable.attach(Label.new(name).set_alignment(1,0), 0, 1, row, row + 1, Gtk::EXPAND | Gtk::FILL, Gtk::SHRINK, 4, 4)
          doctable.attach(Label.new(value).set_alignment(0,0), 1, 2, row, row + 1, Gtk::EXPAND | Gtk::FILL, Gtk::SHRINK, 4, 4)
          
          row = row.succ
        end
        
        docframe.border_width = 5
        docframe.shadow_type = Gtk::SHADOW_IN
        docframe.add(doctable)
        
        pdfframe = Frame.new(" PDF properties ")
        
        labels =
        [
          [ "Version:", "#{pdf.header.to_f} (Acrobat #{ if pdf.header.to_f >= 1.0 and pdf.header.to_f <= 1.7 then @@acrobat_versions[pdf.header.to_f] else "unknown version" end})" ],
          [ "Number of revisions:", "#{pdf.revisions.size}" ],
          [ "Number of indirect objects:", "#{pdf.indirect_objects.size}" ],
          [ "Number of pages:", "#{pdf.pages.size}" ],
          [ "Is linearized:", "#{pdf.is_linearized?}" ],
          [ "Is encrypted:", "#{pdf.is_encrypted?}" ],
          [ "Is signed:", "#{pdf.is_signed?}" ],
          [ "Has usage rights:", "#{pdf.has_usage_rights?}"],
          [ "Contains Acroform:", "#{pdf.has_form?}" ],
          #[ "Contains XFA forms:", "#{pdf.has_xfa_forms?}" ]
          [ "Has document information:", "#{pdf.has_document_info?}" ],
          [ "Has metadata:", "#{pdf.has_metadata?}" ]
        ]
        
        pdftable = Table.new(labels.size + 1, 3)
        
        row = 0
        labels.each do |name, value|
          
          pdftable.attach(Label.new(name).set_alignment(1,0), 0, 1, row, row + 1, Gtk::FILL,  Gtk::SHRINK, 4, 4)
          pdftable.attach(Label.new(value).set_alignment(0,0), 1, 2, row, row + 1, Gtk::EXPAND | Gtk::FILL, Gtk::SHRINK, 4, 4)
          
          row = row.succ
        end
        
        pdfframe.border_width = 5
        pdfframe.shadow_type = Gtk::SHADOW_IN
        pdfframe.add(pdftable)
        
        vbox.add(docframe)
        vbox.add(pdfframe)
        
        signal_connect('response') { destroy }
        
        show_all
      end
      
    end
    
  end

end
