void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/math/registry/placeholders", () => {
        MarkViewer.MathRegistry.reset ();

        int block_id = MarkViewer.MathRegistry.register_block ("\\int_0^1 x\\,dx");
        int inline_id = MarkViewer.MathRegistry.register_inline ("E = mc^2");

        assert_true (MarkViewer.MathRegistry.block_placeholder (block_id) == "⟦BLOCKMATH:0⟧");
        assert_true (MarkViewer.MathRegistry.inline_placeholder (inline_id) == "⟦INLINEMATH:0⟧");
        assert_true (MarkViewer.MathRegistry.get_block (block_id) == "\\int_0^1 x\\,dx");
        assert_true (MarkViewer.MathRegistry.get_inline (inline_id) == "E = mc^2");
        assert_true (MarkViewer.MathRegistry.parse_placeholder_id ("⟦INLINEMATH:0⟧") == 0);
        assert_true (MarkViewer.MathRegistry.is_block_placeholder ("⟦BLOCKMATH:0⟧"));
        assert_true (MarkViewer.MathRegistry.is_inline_placeholder ("⟦INLINEMATH:0⟧"));
    });

    Test.run ();
}