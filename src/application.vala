public class MarkViewer.Application : Adw.Application {
    public Application () {
        Object (
            application_id: "io.github.markviewer",
            flags: ApplicationFlags.HANDLES_COMMAND_LINE | ApplicationFlags.NON_UNIQUE
        );
    }

    public override void activate () {
        hold ();
        var window = new MarkViewer.Window (this);
        window.present ();
        release ();
    }

    public override int command_line (ApplicationCommandLine command_line) {
        hold ();

        string[] args = command_line.get_arguments ();
        string? file_path = null;

        for (int i = 1; i < args.length; i++) {
            if (args[i].has_prefix ("-")) {
                if (args[i] == "--help" || args[i] == "-h") {
                    print_usage (args[0]);
                    release ();
                    return 0;
                }
                continue;
            }

            file_path = args[i];
            break;
        }

        var window = new MarkViewer.Window (this);

        if (file_path != null && !window.open_file (file_path)) {
            release ();
            return 1;
        }

        window.present ();
        release ();
        return 0;
    }

    private void print_usage (string command) {
        stderr.printf ("Usage: %s [path-to-markdown.md]\n", command);
    }
}
