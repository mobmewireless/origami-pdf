=begin

= File
	hexview.rb

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

require 'gui/gtkhex'

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
        
        @view = HexEditor.new
        @view.show_offsets(true)

        add_with_viewport @view
      end

      def clear
        @view.set_data ''
      end

      def load(object)
        return if @current_obj.equal?(object)

        begin
          self.clear

          case object
            when Origami::Stream
              @view.set_data(object.data)
            when Origami::String
              @view.set_data(object.value)
          end

          @current_obj = object

        rescue Exception => e 
          @parent.error("An error occured while loading this object.\n#{e} (#{e.class})")
        end
      end

    end

  end

end
