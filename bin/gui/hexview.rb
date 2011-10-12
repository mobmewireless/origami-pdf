=begin

= File
	hexview.rb

= Info
	This file is part of Origami, PDF manipulation framework for Ruby
	Copyright (C) 2010	Guillaume Delugré <guillaume@security-labs.org>
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

require 'gui/hexdump'

module PDFWalker

  class Walker < Window

    private

    def create_hexview
      @hexview = DumpView.new(self)
    end

    class DumpView < ScrolledWindow
    
      def initialize(parent)
        @parent = parent
        super()

        set_policy(POLICY_AUTOMATIC, POLICY_AUTOMATIC)

        @current_obj = nil
        @valuebuffer = TextBuffer.new
        @valueview = TextView.new(@valuebuffer).set_editable(false).set_cursor_visible(false).set_left_margin(5).set_right_margin(5)

        @valuebuffer.create_tag( "HexView",
          :weight => Pango::WEIGHT_BOLD, 
          #:foreground => "black", 
          :family => "Courier", 
          :scale => Pango::AttrScale::LARGE
        )

        add_with_viewport @valueview
      end

      def clear
        @valuebuffer.set_text("")
      end

      def load(object)
        return if @current_obj.equal?(object)

        begin
          self.clear

          case object
            when Origami::Stream
              @valuebuffer.set_text(object.data.to_s.hexdump)
            when Origami::HexaString
              @valuebuffer.set_text(object.value.to_s.hexdump)
            when Origami::ByteString
              @valuebuffer.set_text(object.to_utf8)
          end

          @valuebuffer.apply_tag("HexView", @valuebuffer.start_iter, @valuebuffer.end_iter)
          @current_obj = object

        rescue Exception => e 
          @parent.error("An error occured while loading this object.\n#{e} (#{e.class})")
        end
      end

    end

  end

end
