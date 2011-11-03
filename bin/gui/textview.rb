=begin

= File
	textview.rb

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
    
    def create_objectview
      @objectview = ObjectView.new(self)
    end
    
    class ObjectView < Notebook
      
      attr_reader :parent
      attr_reader :pdfpanel, :valuepanel
      
      def initialize(parent)
        
        @parent = parent
        
        super()
        
        @pdfbuffer = TextBuffer.new
        @pdfview = TextView.new(@pdfbuffer).set_editable(false).set_cursor_visible(false).set_left_margin(5)
        
        @pdfpanel = ScrolledWindow.new.set_policy(POLICY_AUTOMATIC, POLICY_AUTOMATIC)
        @pdfpanel.add_with_viewport @pdfview
        append_page(@pdfpanel, Label.new("PDF Code"))
        
        @pdfbuffer.create_tag("Object", 
          :weight => Pango::WEIGHT_BOLD, 
          #:foreground => "darkblue", 
          :family => "Courier", 
          :scale => Pango::AttrScale::LARGE
        )
        
      end
      
      def load(object)
      
        begin
          self.clear
        
          pdftag = "Object"
            
          if object.is_a?(Stream)
            stm = "#{object.no} #{object.generation} obj\n"
            stm << object.dictionary.to_s
            
            #if object.rawdata.is_binary_data?
            #  stm << "stream\n[Binary data]\nendstream"
            #else
            #  stm << "stream\n#{object.rawdata}endstream"
            #end
            
            @pdfbuffer.set_text(stm)
            
          elsif (not object.is_a?(::Array) or object.is_a?(Array)) and 
                not object.is_a?(PDF) and not object.is_a?(Adobe::PPKLite) and 
                not object.is_a?(PDF::Revision) and not object.is_a?(Adobe::PPKLite::Revision) and
                not object.is_a?(XRefToCompressedObj)
            
            @pdfbuffer.set_text(object.to_s)
          end
          
          @pdfbuffer.apply_tag(pdftag, @pdfbuffer.start_iter, @pdfbuffer.end_iter)
          
        rescue Exception => e
          @parent.error("An error occured while loading this object.\n#{e} (#{e.class})")
        end
          
      end
      
      def clear
        @pdfbuffer.set_text("")
      end
      
    end
    
  end

end
