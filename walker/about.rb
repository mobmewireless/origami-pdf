=begin

= File
	about.rb

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

module PDFWalker

  class Walker < Window
    
    def about
      
      AboutDialog.show(self, 
        {
          :name => "PDF Walker",
          :program_name => "PDF Walker",
          :version => Origami::VERSION,
          :copyright => "Copyright (C) 2010\nGuillaume Delugre, Sogeti-ESEC R&D <guillaume@security-labs.org>\nAll right reserved.",
          :comments => "A graphical PDF parser front-end",
          :license => File.read("#{File.dirname($0)}/../COPYING.LESSER")
        })
      
    end
    
  end

end
