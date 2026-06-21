namespace MarkViewer {
    public class MathWidget {
        private static double _font_scale = 1.0;

        public static void set_font_scale (double font_scale) {
            _font_scale = font_scale;
            MathRenderer.set_font_scale (font_scale);
        }

        public static void set_foreground (string color) {
            MathRenderer.set_foreground (color);
        }

        public static void reset_for_document () {
            MathRenderer.reset_for_document ();
        }

        public static Gtk.Widget make_block (string latex) {
            var view = MathRenderer.create_view (latex, true);
            if (view == null) {
                return make_source_block (latex);
            }

            var area = make_drawing_area (view, Gtk.Align.CENTER);
            area.add_css_class ("md-math");
            area.add_css_class ("md-math-block");
            area.add_css_class ("md-math-rendered");
            apply_ltr (area);
            return area;
        }

        public static Gtk.Widget make_inline_paragraph (string text) {
            if (!text.contains (MathRegistry.INLINE_PLACEHOLDER_PREFIX)) {
                return make_plain_paragraph (text);
            }

            return MathParagraph.make (text);
        }

        internal static Gtk.DrawingArea make_drawing_area (MarkViewerMath.View view, Gtk.Align halign) {
            uint content_width = 0;
            uint content_height = 0;
            uint baseline = 0;
            view.get_size_pixels (out content_width, out content_height, out baseline);

            var width = (int) content_width;
            var height = (int) content_height;
            if (width < 1) {
                width = 1;
            }
            if (height < 1) {
                height = 1;
            }

            var area = new Gtk.DrawingArea () {
                width_request = width,
                height_request = height,
                halign = halign,
                valign = Gtk.Align.BASELINE_FILL,
                hexpand = halign == Gtk.Align.FILL,
                content_width = width,
                content_height = height,
            };

            area.set_draw_func ((drawing_area, cr, draw_width, draw_height) => {
                cr.save ();
                view.set_resolution (MathRenderer.resolution_ppi ());
                view.get_size_pixels (out content_width, out content_height, out baseline);
                view.render (cr, 0, 0);
                cr.restore ();
            });

            apply_ltr (area);
            return area;
        }

        private static Gtk.Label make_source_block (string latex) {
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

        private static Gtk.Label make_plain_paragraph (string text) {
            var label = new Gtk.Label (null) {
                wrap = true,
                selectable = true,
                hexpand = true,
                halign = Gtk.Align.FILL,
            };
            label.label = text;
            label.add_css_class ("md-math");
            label.add_css_class ("md-math-paragraph");
            apply_rtl_if_needed (label, text);
            return label;
        }

        internal static bool contains_rtl (string text) {
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

        internal static void apply_ltr (Gtk.Widget widget) {
            widget.set_direction (Gtk.TextDirection.LTR);

            if (widget is Gtk.Label) {
                var label = (Gtk.Label) widget;
                label.xalign = 0;
                label.justify = Gtk.Justification.LEFT;
            }
        }

        internal static void apply_rtl_if_needed (Gtk.Widget widget, string? text) {
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