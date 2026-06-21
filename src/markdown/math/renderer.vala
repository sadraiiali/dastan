namespace MarkViewer {
    public class MathRenderer {
        private const double BASE_PPI = 72.0;
        private const double BASE_FONT_PT = 16.0;
        private const double DISPLAY_MATH_SCALE = 1.25;

        private static GLib.HashTable<string, MarkViewerMath.View> _cache =
            new GLib.HashTable<string, MarkViewerMath.View> (str_hash, str_equal);
        private static double _font_scale = 1.0;
        private static string _foreground = "#1f2328";

        public static void set_font_scale (double font_scale) {
            _font_scale = font_scale;
        }

        public static void set_foreground (string color) {
            if (color.length > 0) {
                _foreground = color;
            }
        }

        public static void reset_for_document () {
            _cache = new GLib.HashTable<string, MarkViewerMath.View> (str_hash, str_equal);
        }

        public static double resolution_ppi () {
            return BASE_PPI * _font_scale;
        }

        private static double math_size_pt (bool display) {
            var size = BASE_FONT_PT * _font_scale;
            if (display) {
                size *= DISPLAY_MATH_SCALE;
            }
            return size;
        }

        public static MarkViewerMath.View? create_view (string latex, bool display) {
            var trimmed = latex.strip ();
            if (trimmed.length == 0) {
                return null;
            }

            var ppi = resolution_ppi ();
            var size_pt = math_size_pt (display);
            var key = trimmed + "|" + (display ? "1" : "0") + "|" + ppi.to_string ()
                + "|" + size_pt.to_string () + "|" + _foreground;
            var cached = _cache.lookup (key);
            if (cached != null) {
                return cached;
            }

            var itex = display ? @"$$$trimmed$$" : "$" + trimmed + "$";
            var view = MarkViewerMath.from_latex (itex);
            if (view == null) {
                return null;
            }

            view.set_resolution (resolution_ppi ());
            view.set_math_size (size_pt);
            view.set_foreground (_foreground);
            _cache.insert (key, view);
            return view;
        }
    }
}