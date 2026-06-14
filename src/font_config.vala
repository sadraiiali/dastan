namespace MarkViewer {
    public class FontConfig {
        public static void setup_bundled_fonts () {
            var data_dir = Config.data_dir ();
            var fonts_dir = Path.build_filename (data_dir, "fonts");
            if (!FileUtils.test (fonts_dir, FileTest.IS_DIR)) {
                warning (@"Bundled fonts directory not found: $fonts_dir");
                return;
            }

            var fonts_conf = Config.fonts_conf ();
            if (!FileUtils.test (fonts_conf, FileTest.EXISTS)) {
                warning (@"Fontconfig file not found: $fonts_conf");
                return;
            }

            // Leave an existing FONTCONFIG_FILE alone — GTK may have already
            // initialized fontconfig from the environment (e.g. make run).
            if (Environment.get_variable ("FONTCONFIG_FILE") == null) {
                Environment.set_variable ("FONTCONFIG_FILE", fonts_conf, true);
            }
        }
    }
}