=begin

= File
	origami.rb

= Info
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


if RUBY_VERSION < '1.9'
  class Fixnum
    def ord; self; end
  end

  class Hash
    alias key index
  end
end

require 'origami/parsers/pdf'
require 'origami/parsers/fdf'
require 'origami/parsers/ppklite'

