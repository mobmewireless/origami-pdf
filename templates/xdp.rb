=begin

= File
	xdp.rb

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

module Origami

  module Template

    class XMLForm < XDP::Package
      def initialize(script = "")
        super()

        self.root.add_element(create_config_packet)
        self.root.add_element(create_template_packet(script))
        self.root.add_element(create_datasets_packet)
      end

      def create_config_packet
        config = XDP::Packet::Config.new
        
        present = config.add_element(XFA::Element.new("present"))
        pdf = present.add_element(XFA::Element.new("pdf"))
        interactive = pdf.add_element(XFA::Element.new("interactive"))
        interactive.text = 1

        config
      end

      def create_template_packet(script)
        template = XDP::Packet::Template.new
        
        form1 = template.add_subform(:layout => 'tb', :name => 'form1')
        form1.add_pageSet
        form1.add_event(:activity => 'initialize', :name => 'event__ready').
          add_script(:contentType => 'application/x-formcalc').
            text = script
        
        subform = form1.add_subform

        button = subform.add_field(:name => 'Button1')
        button.add_ui.add_button(:highlight => 'inverted')
        btncaption = button.add_caption
        btncaption.add_value.add_text.text = "Send!"
        btncaption.add_para(:vAlign => 'middle', :hAlign => 'center')
        button.add_bind(:match => 'none')
        button.add_event(:activity => 'click', :name => 'event__click').
          add_script(:contentType => 'application/x-formcalc').
            text = script

        txtfield = subform.add_field(:name => 'TextField1')
        txtfield.add_ui.add_textEdit.add_border.add_edge(:stroke => 'lowered')

        template
      end

      def create_datasets_packet
        datasets = XDP::Packet::Datasets.new
        data = datasets.add_element(XDP::Packet::Datasets::Data.new)

        data.
          add_element(XFA::Element.new('form1')).
            add_element(XFA::Element.new('TextField1')).
              text = '$host.messageBox("test")'

        datasets
      end
    end

  end

end
