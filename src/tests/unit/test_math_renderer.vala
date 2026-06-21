void main (string[] args) {
    Gtk.init ();

    Test.init (ref args);

    Test.add_func ("/math/renderer/inline-formula", () => {
        MarkViewer.MathRenderer.reset_for_document ();
        var view = MarkViewer.MathRenderer.create_view ("E = mc^2", false);
        assert_nonnull (view);

        uint width = 0;
        uint height = 0;
        uint baseline = 0;
        view.get_size_pixels (out width, out height, out baseline);
        assert_true (width > 0);
        assert_true (height > 0);
    });

    Test.add_func ("/math/renderer/block-integral", () => {
        MarkViewer.MathRenderer.reset_for_document ();
        var view = MarkViewer.MathRenderer.create_view ("\\int_0^1 x^2\\,dx", true);
        assert_nonnull (view);
    });

    Test.add_func ("/math/renderer/invalid-fallback", () => {
        MarkViewer.MathRenderer.reset_for_document ();
        var view = MarkViewer.MathRenderer.create_view ("\\bad{", false);
        assert_null (view);
    });

    Test.add_func ("/math/renderer/block-matrix", () => {
        MarkViewer.MathRenderer.reset_for_document ();
        var latex = "\\begin{bmatrix}\n1 & 2 & 3 \\\\\n4 & 5 & 6 \\\\\n7 & 8 & 9\n\\end{bmatrix}";
        var view = MarkViewer.MathRenderer.create_view (latex, true);
        assert_nonnull (view);

        uint width = 0;
        uint height = 0;
        uint baseline = 0;
        view.get_size_pixels (out width, out height, out baseline);
        assert_true (width > 30);
        assert_true (height > 30);
        assert_true (width > height);
    });

    Test.run ();
}