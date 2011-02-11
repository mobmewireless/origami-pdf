require 'test/unit'
require 'stringio'

  class TC_Annotations< Test::Unit::TestCase
    def setup
      @target = PDF.new
      @page = Page.new
      @action = Action::JavaScript.new "app.alert(null);"
      @output = StringIO.new
    end

    # def teardown
    # end

    def test_annotations
      
      circle = Annotation::Circle.new
      square = Annotation::Square.new
      text = Annotation::Text.new
      link = Annotation::Link.new
      file = Annotation::FileAttachment.new
      screen = Annotation::Screen.new
      sound = Annotation::Sound.new
      pushbutton = Annotation::Widget::PushButton.new
      checkbox = Annotation::Widget::CheckBox.new
      radio = Annotation::Widget::Radio.new
      edit = Annotation::Widget::Text.new
      combo = Annotation::Widget::ComboBox.new
      list = Annotation::Widget::ListBox.new
      sig = Annotation::Widget::Signature.new

      @target.append_page @page

      assert_nothing_raised do
        @page.add_annot circle
        @page.add_annot square
        @page.add_annot text
        @page.add_annot link
        @page.add_annot file
        @page.add_annot screen
        @page.add_annot sound
        @page.add_annot pushbutton
        @page.add_annot checkbox
        @page.add_annot radio
        @page.add_annot edit
        @page.add_annot combo
        @page.add_annot list
        @page.add_annot sig
      end

      assert_nothing_raised do
        @target.save(@output)
      end
    end

    def test_annotation_actions
      
      screen = Annotation::Screen.new

      @page.add_annot screen
      
      screen.onMouseOver @action
      screen.onMouseOut @action
      screen.onMouseDown @action
      screen.onMouseUp @action
      screen.onFocus @action
      screen.onBlur @action
      screen.onPageOpen @action
      screen.onPageClose @action
      screen.onPageVisible @action
      screen.onPageInvisible @action

      assert_equal screen.AA.E, @action
      assert_equal screen.AA.X, @action
      assert_equal screen.AA.D, @action
      assert_equal screen.AA.U, @action
      assert_equal screen.AA.Fo, @action
      assert_equal screen.AA.Bl, @action
      assert_equal screen.AA.PO, @action
      assert_equal screen.AA.PC, @action
      assert_equal screen.AA.PV, @action
      assert_equal screen.AA.PI, @action
    end

end
