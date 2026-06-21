namespace MarkViewer {
    public class MathParagraph : Gtk.Box {
        construct {
            orientation = Gtk.Orientation.HORIZONTAL;
            spacing = 4;
            homogeneous = false;
            hexpand = true;
            halign = Gtk.Align.FILL;
            add_css_class ("md-math");
            add_css_class ("md-math-paragraph");
            add_css_class ("md-math-rendered");
        }

        public static Gtk.Widget make (string text) {
            var box = new MathParagraph ();
            box.build_segments (text);
            MathWidget.apply_rtl_if_needed (box, box.visible_text (text));
            return box;
        }

        private void build_segments (string text) {
            int pos = 0;

            while (pos < text.length) {
                int marker_start = text.index_of (MathRegistry.INLINE_PLACEHOLDER_PREFIX, pos);
                if (marker_start < 0) {
                    append_text (text.substring (pos));
                    break;
                }

                if (marker_start > pos) {
                    append_text (text.substring (pos, marker_start - pos));
                }

                int marker_end = text.index_of (MathRegistry.PLACEHOLDER_SUFFIX, marker_start);
                if (marker_end < 0) {
                    append_text (text.substring (marker_start));
                    break;
                }

                marker_end += MathRegistry.PLACEHOLDER_SUFFIX.length;
                var placeholder = text.substring (marker_start, marker_end - marker_start);
                var formula_id = MathRegistry.parse_placeholder_id (placeholder);
                var latex = MathRegistry.get_inline (formula_id);
                if (latex != null) {
                    append_math (latex);
                } else {
                    append_text (placeholder);
                }

                pos = marker_end;
            }
        }

        private void append_text (string chunk) {
            if (chunk.length == 0) {
                return;
            }

            var label = new Gtk.Label (null) {
                wrap = false,
                selectable = true,
                valign = Gtk.Align.BASELINE_FILL,
                vexpand = false,
                hexpand = false,
            };
            label.label = chunk;
            label.add_css_class ("md-paragraph");
            append (label);
        }

        private void append_math (string latex) {
            var view = MathRenderer.create_view (latex, false);
            if (view == null) {
                var fallback = new Gtk.Label (null) {
                    wrap = false,
                    selectable = true,
                    valign = Gtk.Align.BASELINE_FILL,
                };
                fallback.label = latex.strip ();
                fallback.add_css_class ("md-math-source");
                MathWidget.apply_ltr (fallback);
                append (fallback);
                return;
            }

            append (MathWidget.make_drawing_area (view, Gtk.Align.START));
        }

        private string visible_text (string text) {
            var builder = new StringBuilder ();
            int pos = 0;

            while (pos < text.length) {
                int marker_start = text.index_of (MathRegistry.INLINE_PLACEHOLDER_PREFIX, pos);
                if (marker_start < 0) {
                    builder.append (text.substring (pos));
                    break;
                }

                if (marker_start > pos) {
                    builder.append (text.substring (pos, marker_start - pos));
                }

                int marker_end = text.index_of (MathRegistry.PLACEHOLDER_SUFFIX, marker_start);
                if (marker_end < 0) {
                    builder.append (text.substring (marker_start));
                    break;
                }

                marker_end += MathRegistry.PLACEHOLDER_SUFFIX.length;
                var placeholder = text.substring (marker_start, marker_end - marker_start);
                var formula_id = MathRegistry.parse_placeholder_id (placeholder);
                var resolved = MathRegistry.get_inline (formula_id);
                builder.append (resolved ?? placeholder);
                pos = marker_end;
            }

            return builder.str;
        }
    }
}