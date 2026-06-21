namespace MarkViewer {
    public class FontConfig {
        private static string? _appimage_fonts_conf;

        public static void setup_bundled_fonts () {
            var data_dir = Config.data_dir ();
            var fonts_dir = Path.build_filename (data_dir, "fonts");
            if (!FileUtils.test (fonts_dir, FileTest.IS_DIR)) {
                warning (@"Bundled fonts directory not found: $fonts_dir");
                return;
            }

            var fonts_conf = Config.fonts_conf ();
            if (Environment.get_variable ("APPDIR") != null) {
                fonts_conf = ensure_appimage_fonts_conf (fonts_dir);
            } else if (!FileUtils.test (fonts_conf, FileTest.EXISTS)) {
                warning (@"Fontconfig file not found: $fonts_conf");
                return;
            }

            // Leave an existing FONTCONFIG_FILE alone — GTK may have already
            // initialized fontconfig from the environment (e.g. make run).
            if (Environment.get_variable ("FONTCONFIG_FILE") == null) {
                Environment.set_variable ("FONTCONFIG_FILE", fonts_conf, true);
            }
        }

        private static string ensure_appimage_fonts_conf (string fonts_dir) {
            if (_appimage_fonts_conf != null) {
                return _appimage_fonts_conf;
            }

            var cache_dir = Path.build_filename (Environment.get_user_cache_dir (), "dastan");
            DirUtils.create_with_parents (cache_dir, 0755);

            var conf_path = Path.build_filename (cache_dir, "dastan-fonts.conf");
            var math_dir = Path.build_filename (fonts_dir, "math");
            var contents = """<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <include ignore_missing="yes">/etc/fonts/fonts.conf</include>
  <dir>@fonts_dir@</dir>
  <dir>@math_dir@</dir>
</fontconfig>
""".replace ("@fonts_dir@", fonts_dir).replace ("@math_dir@", math_dir);

            try {
                FileUtils.set_contents (conf_path, contents);
            } catch (Error err) {
                var details = err.message;
                warning (@"Failed to write AppImage fontconfig file: $conf_path ($details)");
                return Config.fonts_conf ();
            }

            _appimage_fonts_conf = conf_path;
            return conf_path;
        }
    }
}