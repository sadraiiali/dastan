[CCode (cheader_filename = "lasem_bridge.h")]
namespace MarkViewerMath {
    [Compact]
    [CCode (cname = "MarkViewerMathView", ref_function = "markviewer_math_view_ref", unref_function = "markviewer_math_view_unref")]
    public class View {
        [CCode (cname = "markviewer_math_view_set_resolution")]
        public void set_resolution (double ppi);

        [CCode (cname = "markviewer_math_view_set_foreground")]
        public void set_foreground (string color);

        [CCode (cname = "markviewer_math_view_set_math_size")]
        public void set_math_size (double size_pt);

        [CCode (cname = "markviewer_math_view_get_size_pixels")]
        public void get_size_pixels (out uint width, out uint height, out uint baseline);

        [CCode (cname = "markviewer_math_view_render")]
        public void render (Cairo.Context cr, double x, double y);
    }

    [CCode (cname = "markviewer_math_view_from_latex")]
    public static View? from_latex (string latex, out GLib.Error? error = null);
}