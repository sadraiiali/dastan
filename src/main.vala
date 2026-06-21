public int main (string[] args) {
    MarkViewer.FontConfig.setup_bundled_fonts ();
    if (Environment.get_variable ("GSETTINGS_SCHEMA_DIR") == null) {
        Environment.set_variable (
            "GSETTINGS_SCHEMA_DIR",
            MarkViewer.Config.schemas_dir (),
            true
        );
    }
    var app = new MarkViewer.Application ();
    return app.run (args);
}