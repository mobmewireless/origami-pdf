=begin

= File
	about.rb

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
    
    def about
      
      AboutDialog.show(self, 
        {
          :name => "PDF Walker",
          :program_name => "PDF Walker",
          :version => Origami::VERSION,
          :copyright => "Copyright (C) 2010\nGuillaume Delugre <guillaume@security-labs.org>\nAll right reserved.",
          :comments => "A graphical PDF parser front-end",
          :license => File.read("#{File.dirname(__FILE__)}/COPYING")
        })
      
    end
    
  end

end
