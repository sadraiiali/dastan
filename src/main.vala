public int main (string[] args) {
    MarkViewer.FontConfig.setup_bundled_fonts ();
    var app = new MarkViewer.Application ();
    return app.run (args);
}