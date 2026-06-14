namespace MarkViewer {
    public class MathWidget {
        private static double _font_scale = 1.0;

        public static void set_font_scale (double font_scale) {
            _font_scale = font_scale;
        }

        public static void reset_for_document () {
            // No per-document state for native LaTeX labels.
        }

        public static Gtk.Widget make_block (string latex) {
            var label = new Gtk.Label (null) {
                wrap = true,
                selectable = true,
                justify = Gtk.Justification.CENTER,
                halign = Gtk.Align.CENTER,
                hexpand = true,
            };
            label.label = latex.strip ();
            label.add_css_class ("md-math");
            label.add_css_class ("md-math-block");
            label.add_css_class ("md-math-source");
            apply_ltr (label);
            return label;
        }

        public static Gtk.Widget make_inline_paragraph (string text) {
            var label = new Gtk.Label (null) {
                wrap = true,
                selectable = true,
                hexpand = true,
                halign = Gtk.Align.FILL,
            };
            set_inline_paragraph_markup (label, text);
            label.add_css_class ("md-math");
            label.add_css_class ("md-math-paragraph");
            label.add_css_class ("md-math-source");
            apply_rtl_if_needed (label, visible_text (text));
            return label;
        }

        private static void set_inline_paragraph_markup (Gtk.Label label, string text) {
            var markup = build_inline_paragraph_markup (text);
            if (markup.length == 0) {
                label.label = text;
                return;
            }

            try {
                label.set_markup (markup);
            } catch (MarkupError e) {
                label.label = visible_text (text);
            }
        }

        private static string build_inline_paragraph_markup (string text) {
            var builder = new StringBuilder ();
            int pos = 0;

            while (pos < text.length) {
                int marker_start = text.index_of (MathRegistry.INLINE_PLACEHOLDER_PREFIX, pos);
                if (marker_start < 0) {
                    builder.append (Markup.escape_text (text.substring (pos)));
                    break;
                }

                if (marker_start > pos) {
                    builder.append (Markup.escape_text (text.substring (pos, marker_start - pos)));
                }

                int marker_end = text.index_of (MathRegistry.PLACEHOLDER_SUFFIX, marker_start);
                if (marker_end < 0) {
                    builder.append (Markup.escape_text (text.substring (marker_start)));
                    break;
                }

                marker_end += MathRegistry.PLACEHOLDER_SUFFIX.length;
                var placeholder = text.substring (marker_start, marker_end - marker_start);
                var formula_id = MathRegistry.parse_placeholder_id (placeholder);
                var latex = MathRegistry.get_inline (formula_id) ?? placeholder;
                builder.append (@"<span font_family=\"Noto Sans Mono\"><tt>$(Markup.escape_text (latex.strip ()))</tt></span>");
                pos = marker_end;
            }

            return builder.str;
        }

        private static string visible_text (string text) {
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
                var latex = MathRegistry.get_inline (formula_id);
                builder.append (latex ?? placeholder);
                pos = marker_end;
            }

            return builder.str;
        }

        private static bool contains_rtl (string text) {
            for (int i = 0; i < text.char_count (); i++) {
                unichar character = text.get_char (text.index_of_nth_char (i));
                if ((character >= 0x0600 && character <= 0x06ff)
                    || (character >= 0x0750 && character <= 0x077f)
                    || (character >= 0x08a0 && character <= 0x08ff)
                    || (character >= 0xfb50 && character <= 0xfdff)
                    || (character >= 0xfe70 && character <= 0xfeff)) {
                    return true;
                }
            }

            return false;
        }

        private static void apply_ltr (Gtk.Widget widget) {
            widget.set_direction (Gtk.TextDirection.LTR);

            if (widget is Gtk.Label) {
                var label = (Gtk.Label) widget;
                label.xalign = 0;
                label.justify = Gtk.Justification.LEFT;
            }
        }

        private static void apply_rtl_if_needed (Gtk.Widget widget, string? text) {
            if (text == null || !contains_rtl (text)) {
                apply_ltr (widget);
                return;
            }

            widget.set_direction (Gtk.TextDirection.RTL);

            if (widget is Gtk.Label) {
                var label = (Gtk.Label) widget;
                label.xalign = 0;
                label.justify = Gtk.Justification.LEFT;
            }
        }
    }
}