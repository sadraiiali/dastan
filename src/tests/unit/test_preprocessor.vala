void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/preprocessor/inline-dollar", () => {
        var result = MarkViewer.MarkdownPreprocessor.preprocess ("Energy $E = mc^2$ here.");
        assert_true (result.contains (MarkViewer.MathRegistry.INLINE_PLACEHOLDER_PREFIX));
        assert_false (result.contains ("$E = mc^2$"));
    });

    Test.add_func ("/preprocessor/block-dollar", () => {
        var result = MarkViewer.MarkdownPreprocessor.preprocess ("$$\n\\int_0^1 x\\,dx\n$$");
        assert_true (result.contains (MarkViewer.MathRegistry.BLOCK_PLACEHOLDER_PREFIX));
    });

    Test.add_func ("/preprocessor/skips-fenced-code", () => {
        var result = MarkViewer.MarkdownPreprocessor.preprocess ("```\n$x$\n```");
        assert_true (result.contains ("$x$"));
        assert_false (result.contains (MarkViewer.MathRegistry.INLINE_PLACEHOLDER_PREFIX));
    });

    Test.add_func ("/preprocessor/paren-delimiters", () => {
        var result = MarkViewer.MarkdownPreprocessor.preprocess ("Inline \\(a+b\\) and block \\[c+d\\]");
        assert_true (result.contains (MarkViewer.MathRegistry.INLINE_PLACEHOLDER_PREFIX));
        assert_true (result.contains (MarkViewer.MathRegistry.BLOCK_PLACEHOLDER_PREFIX));
    });

    Test.run ();
}