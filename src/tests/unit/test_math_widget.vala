void main (string[] args) {
    Gtk.init ();

    Test.init (ref args);

    Test.add_func ("/math/widget/block-renders-drawing-area", () => {
        MarkViewer.MathWidget.reset_for_document ();
        var widget = MarkViewer.MathWidget.make_block ("E = mc^2");
        assert_true (widget is Gtk.DrawingArea);
        assert_true (widget.has_css_class ("md-math-rendered"));
    });

    Test.add_func ("/math/widget/block-fallback-label", () => {
        MarkViewer.MathWidget.reset_for_document ();
        var widget = MarkViewer.MathWidget.make_block ("\\totallyinvalid{");
        assert_true (widget is Gtk.Label);
        assert_true (widget.has_css_class ("md-math-source"));
    });

    Test.add_func ("/math/widget/inline-paragraph", () => {
        MarkViewer.MathRegistry.reset ();
        MarkViewer.MathWidget.reset_for_document ();
        var id = MarkViewer.MathRegistry.register_inline ("x^2");
        var placeholder = MarkViewer.MathRegistry.inline_placeholder (id);
        var text = "Energy " + placeholder + " today.";
        var widget = MarkViewer.MathWidget.make_inline_paragraph (text);
        assert_true (widget is MarkViewer.MathParagraph);
    });

    Test.run ();
}