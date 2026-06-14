public class MarkViewer.Window : Adw.ApplicationWindow {
    private const double FONT_SCALE_MIN = 0.75;
    private const double FONT_SCALE_MAX = 2.5;
    private const double FONT_SCALE_STEP = 0.1;
    private const double CONTENT_MAX_WIDTH_REM = 31.25;
    private const double DEFAULT_WINDOW_WIDTH_REM = 40.0;
    private const double DEFAULT_WINDOW_HEIGHT_REM = 45.0;

    private Gtk.ScrolledWindow _scrolled;
    private Adw.HeaderBar _header;
    private Gtk.Label _title_label;
    private Gtk.Label? _zoom_value_label;
    private Adw.Dialog? _settings_dialog;
    private string? _current_path;
    private string? _current_contents;
    private double _font_scale = 1.0;
    private Gtk.CssProvider? _zoom_provider;
    private Adw.Clamp? _content_clamp;

    public Window (MarkViewer.Application app) {
        Object (application: app);
    }

    construct {
        default_width = rem_to_layout_units (DEFAULT_WINDOW_WIDTH_REM);
        default_height = rem_to_layout_units (DEFAULT_WINDOW_HEIGHT_REM);
        title = "MarkViewer";

        load_styles ();

        _header = new Adw.HeaderBar ();
        _title_label = new Gtk.Label (null);
        _title_label.add_css_class ("title");
        _title_label.set_hexpand (true);
        _title_label.set_ellipsize (Pango.EllipsizeMode.MIDDLE);
        _header.title_widget = _title_label;

        var settings_button = new Gtk.Button () {
            tooltip_text = "View settings",
            icon_name = "emblem-system-symbolic",
        };
        settings_button.add_css_class ("flat");
        settings_button.clicked.connect (show_settings_dialog);
        _header.pack_start (settings_button);

        _scrolled = new Gtk.ScrolledWindow () {
            vexpand = true,
            hexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vscrollbar_policy = Gtk.PolicyType.AUTOMATIC,
        };
        _scrolled.child = wrap_content (make_empty_state ());

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (_header);
        toolbar_view.content = _scrolled;
        content = toolbar_view;

        setup_zoom_shortcuts ();
        setup_scroll_zoom ();
        apply_font_scale_css ();
    }

    public bool open_file (string path) {
        string resolved;
        if (Path.is_absolute (path)) {
            resolved = path;
        } else {
            resolved = Path.build_filename (Environment.get_current_dir (), path);
        }

        if (!FileUtils.test (resolved, FileTest.EXISTS)) {
            stderr.printf ("dastan: file not found: %s\n", path);
            return false;
        }

        if (!FileUtils.test (resolved, FileTest.IS_REGULAR)) {
            stderr.printf ("dastan: not a regular file: %s\n", resolved);
            return false;
        }

        string? contents = null;
        try {
            FileUtils.get_contents (resolved, out contents);
        } catch (FileError e) {
            stderr.printf ("dastan: failed to read %s: %s\n", resolved, e.message);
            return false;
        }

        _current_path = resolved;
        _current_contents = contents;
        _title_label.label = Path.get_basename (resolved);
        title = _title_label.label + " — MarkViewer";
        refresh_content ();
        return true;
    }

    private Gtk.Widget wrap_content (Gtk.Widget widget) {
        apply_content_width (widget);

        _content_clamp = new Adw.Clamp () {
            maximum_size = rem_to_layout_units (CONTENT_MAX_WIDTH_REM),
            tightening_threshold = rem_to_layout_units (CONTENT_MAX_WIDTH_REM),
            child = widget,
        };
        _content_clamp.add_css_class ("md-content-column");

        return _content_clamp;
    }

    private double scaled_rem_size () {
        var settings = Gtk.Settings.get_default ();
        var desc = Pango.FontDescription.from_string (settings.gtk_font_name ?? "sans 10");
        return (double) desc.get_size () / Pango.SCALE * (96.0 / 72.0) * _font_scale;
    }

    private int rem_to_layout_units (double rem) {
        return (int) (rem * scaled_rem_size () + 0.5);
    }

    private void apply_content_width (Gtk.Widget widget) {
        widget.hexpand = true;
        widget.halign = Gtk.Align.FILL;
    }

    private Gtk.Widget make_empty_state () {
        var label = new Gtk.Label ("Pass a markdown file path on the command line.\n\ndastan /path/to/notes.md") {
            wrap = true,
            xalign = 0,
            hexpand = true,
            halign = Gtk.Align.FILL,
        };
        label.add_css_class ("md-empty");
        label.add_css_class ("markdown-body");
        return label;
    }

    private void setup_zoom_shortcuts () {
        var key_controller = new Gtk.EventControllerKey ();
        key_controller.key_pressed.connect ((keyval, keycode, state) => {
            if ((state & Gdk.ModifierType.CONTROL_MASK) == 0) {
                return false;
            }

            if (keyval == Gdk.Key.equal || keyval == Gdk.Key.plus) {
                change_font_scale (FONT_SCALE_STEP);
                return true;
            }

            if (keyval == Gdk.Key.minus) {
                change_font_scale (-FONT_SCALE_STEP);
                return true;
            }

            return false;
        });
        ((Gtk.Widget) this).add_controller (key_controller);
    }

    private void setup_scroll_zoom () {
        var scroll_controller = new Gtk.EventControllerScroll (
            Gtk.EventControllerScrollFlags.VERTICAL
        );
        scroll_controller.scroll.connect ((dx, dy) => {
            var state = scroll_controller.get_current_event_state ();
            if ((state & Gdk.ModifierType.CONTROL_MASK) == 0) {
                return false;
            }

            if (dy < 0) {
                change_font_scale (FONT_SCALE_STEP);
            } else if (dy > 0) {
                change_font_scale (-FONT_SCALE_STEP);
            }

            return true;
        });
        _scrolled.add_controller (scroll_controller);
    }

    private void show_settings_dialog () {
        if (_settings_dialog != null) {
            _settings_dialog.present (this);
            return;
        }

        var title_label = new Gtk.Label ("View Settings") {
            xalign = 0,
            hexpand = true,
        };
        title_label.add_css_class ("title-3");

        var subtitle_label = new Gtk.Label ("Zoom and typography") {
            xalign = 0,
            hexpand = true,
        };
        subtitle_label.add_css_class ("dim-label");

        var font_caption = new Gtk.Label ("Persian font") {
            xalign = 0,
            hexpand = true,
        };
        font_caption.add_css_class ("heading");

        var font_name_label = new Gtk.Label ("Shabnam") {
            xalign = 0,
            hexpand = true,
        };
        font_name_label.add_css_class ("title-4");

        var font_detail_label = new Gtk.Label ("Bundled in MarkViewer for Farsi and Arabic text.") {
            xalign = 0,
            hexpand = true,
            wrap = true,
        };
        font_detail_label.add_css_class ("dim-label");

        var font_preview_label = new Gtk.Label ("نمونه متن فارسی — فونت شبنم") {
            xalign = 0,
            hexpand = true,
            wrap = true,
            justify = Gtk.Justification.LEFT,
        };
        font_preview_label.add_css_class ("md-settings-font-preview");
        font_preview_label.set_direction (Gtk.TextDirection.RTL);

        var zoom_caption = new Gtk.Label ("Zoom") {
            xalign = 0,
            hexpand = true,
        };
        zoom_caption.add_css_class ("heading");

        _zoom_value_label = new Gtk.Label (format_zoom_percent ()) {
            xalign = 0.5f,
            hexpand = true,
        };
        _zoom_value_label.add_css_class ("title-2");

        var zoom_out_button = new Gtk.Button () {
            icon_name = "list-remove-symbolic",
            tooltip_text = "Zoom out",
        };
        zoom_out_button.clicked.connect (() => change_font_scale (-FONT_SCALE_STEP));

        var zoom_in_button = new Gtk.Button () {
            icon_name = "list-add-symbolic",
            tooltip_text = "Zoom in",
        };
        zoom_in_button.clicked.connect (() => change_font_scale (FONT_SCALE_STEP));

        var zoom_controls = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            homogeneous = true,
            hexpand = true,
            halign = Gtk.Align.FILL,
        };
        zoom_controls.append (zoom_out_button);
        zoom_controls.append (_zoom_value_label);
        zoom_controls.append (zoom_in_button);

        var reset_button = new Gtk.Button.with_label ("Reset");
        reset_button.hexpand = true;
        reset_button.clicked.connect (reset_font_scale);

        var hint = new Gtk.Label ("Use Ctrl + +, Ctrl + −, or Ctrl + scroll wheel.") {
            wrap = true,
            xalign = 0,
        };
        hint.add_css_class ("dim-label");

        var close_button = new Gtk.Button.with_label ("Close");
        close_button.hexpand = true;
        close_button.clicked.connect (() => {
            if (_settings_dialog != null) {
                _settings_dialog.close ();
            }
        });

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 16) {
            margin_top = 24,
            margin_bottom = 24,
            margin_start = 24,
            margin_end = 24,
            width_request = 320,
        };
        content.append (title_label);
        content.append (subtitle_label);
        content.append (font_caption);
        content.append (font_name_label);
        content.append (font_detail_label);
        content.append (font_preview_label);
        content.append (zoom_caption);
        content.append (zoom_controls);
        content.append (reset_button);
        content.append (hint);
        content.append (close_button);

        var dialog = new Adw.Dialog () {
            title = "View Settings",
            child = content,
            can_close = true,
            follows_content_size = true,
            content_width = 360,
            presentation_mode = Adw.DialogPresentationMode.AUTO,
        };
        _settings_dialog = dialog;

        dialog.closed.connect (() => {
            _settings_dialog = null;
            _zoom_value_label = null;
        });

        setup_settings_dialog_dismiss (dialog, content);

        dialog.present (this);
    }

    private void setup_settings_dialog_dismiss (Adw.Dialog dialog, Gtk.Widget content) {
        var dismiss_gesture = new Gtk.GestureClick ();
        dismiss_gesture.set_propagation_phase (Gtk.PropagationPhase.CAPTURE);
        dismiss_gesture.released.connect ((n_press, x, y) => {
            var dialog_widget = (Gtk.Widget) dialog;
            var picked = dialog_widget.pick (x, y, Gtk.PickFlags.DEFAULT);
            if (picked == null) {
                dialog.close ();
                return;
            }

            if (picked == content) {
                return;
            }

            if (picked is Gtk.Widget) {
                var picked_widget = (Gtk.Widget) picked;
                if (is_widget_descendant_of (picked_widget, content)) {
                    return;
                }
            }

            dialog.close ();
        });
        ((Gtk.Widget) dialog).add_controller (dismiss_gesture);
    }

    private bool is_widget_descendant_of (Gtk.Widget? widget, Gtk.Widget ancestor) {
        for (var current = widget; current != null; current = current.get_parent () as Gtk.Widget) {
            if (current == ancestor) {
                return true;
            }
        }
        return false;
    }

    private string format_zoom_percent () {
        return "%d%%".printf ((int) (_font_scale * 100 + 0.5));
    }

    private void update_zoom_label () {
        if (_zoom_value_label != null) {
            _zoom_value_label.label = format_zoom_percent ();
        }
    }

    private void reset_font_scale () {
        set_font_scale (1.0);
    }

    private void change_font_scale (double delta) {
        set_font_scale (_font_scale + delta);
    }

    private void set_font_scale (double scale) {
        scale = double.max (FONT_SCALE_MIN, double.min (FONT_SCALE_MAX, scale));
        if (Math.fabs (scale - _font_scale) < 0.001) {
            return;
        }

        _font_scale = scale;
        apply_font_scale_css ();
        update_content_clamp ();
        update_zoom_label ();

        var scroll_y = _scrolled.get_vadjustment ().get_value ();
        refresh_content ();
        _scrolled.get_vadjustment ().set_value (scroll_y);
    }

    private void apply_font_scale_css () {
        if (_zoom_provider == null) {
            _zoom_provider = new Gtk.CssProvider ();
            Gtk.StyleContext.add_provider_for_display (
                Gdk.Display.get_default (),
                _zoom_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION + 1
            );
        }

        _zoom_provider.load_from_string (
            ".markdown-body, .md-content-column { --md-scale: %.4f; }".printf (_font_scale)
        );
    }

    private void update_content_clamp () {
        if (_content_clamp == null) {
            return;
        }

        var max_width = rem_to_layout_units (CONTENT_MAX_WIDTH_REM);
        _content_clamp.maximum_size = max_width;
        _content_clamp.tightening_threshold = max_width;
    }

    private void refresh_content () {
        if (_current_contents != null) {
            _scrolled.child = wrap_content (
                MarkViewer.MarkdownRenderer.render (_current_contents, _font_scale)
            );
            return;
        }

        _scrolled.child = wrap_content (make_empty_state ());
    }

    private void load_styles () {
        var css_path = Path.build_filename (MarkViewer.Config.data_dir (), "markviewer.css");
        if (!FileUtils.test (css_path, FileTest.EXISTS)) {
            warning (@"Stylesheet not found: $css_path");
            return;
        }

        var provider = new Gtk.CssProvider ();
        provider.load_from_path (css_path);
        Gtk.StyleContext.add_provider_for_display (
            Gdk.Display.get_default (),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }
}