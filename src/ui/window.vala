[CCode (cname = "gtk_style_context_add_provider_for_display")]
extern void gtk_add_css_provider_for_display (Gdk.Display display, Gtk.StyleProvider provider, uint priority);

public class MarkViewer.Window : Adw.ApplicationWindow {
    private const double FONT_SCALE_MIN = 0.75;
    private const double FONT_SCALE_MAX = 2.5;
    private const double FONT_SCALE_STEP = 0.1;
    private const double CONTENT_MAX_WIDTH_REM = 31.25;
    private const double DEFAULT_WINDOW_WIDTH_REM = 40.0;
    private const double DEFAULT_WINDOW_HEIGHT_REM = 45.0;
    private const int SETTINGS_DIALOG_WIDTH = 400;
    private const int SETTINGS_DIALOG_HEIGHT = 600;

    private const string[] MARKDOWN_THEME_IDS = {
        "auto",
        "light",
        "dark",
        "dark-dimmed",
        "dark-high-contrast",
        "dark-colorblind",
        "light-colorblind",
    };

    private const string[] MARKDOWN_THEME_LABELS = {
        "System (Auto)",
        "Light",
        "Dark",
        "Dark Dimmed",
        "Dark High Contrast",
        "Dark Colorblind",
        "Light Colorblind",
    };

    private Gtk.ScrolledWindow _scrolled;
    private Adw.HeaderBar _header;
    private Gtk.Label _title_label;
    private Gtk.Label? _zoom_value_label;
    private Adw.ActionRow? _theme_row;
    private Gtk.DropDown? _theme_dropdown;
    private Adw.SwitchRow? _container_row;
    private Adw.Dialog? _settings_dialog;
    private GLib.Settings? _settings;
    private string? _current_path;
    private string? _current_contents;
    private string _markdown_theme = "auto";
    private bool _show_content_container = true;
    private double _font_scale = 1.0;
    private Gtk.CssProvider? _zoom_provider;
    private Gtk.CssProvider? _theme_provider;
    private Adw.Clamp? _content_clamp;

    public Window (MarkViewer.Application app) {
        Object (application: app);
    }

    construct {
        default_width = rem_to_layout_units (DEFAULT_WINDOW_WIDTH_REM);
        default_height = rem_to_layout_units (DEFAULT_WINDOW_HEIGHT_REM);
        title = "MarkViewer";

        load_styles ();
        load_preferences ();

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

        var open_button = new Gtk.Button () {
            tooltip_text = "Open markdown file",
            icon_name = "document-open-symbolic",
        };
        open_button.add_css_class ("suggested-action");
        open_button.clicked.connect (show_open_file_dialog);
        _header.pack_end (open_button);

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
        setup_file_drop (_scrolled);
        ((Gtk.Widget) _scrolled).notify["allocation"].connect (update_empty_state_layout);
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

        if (_show_content_container) {
            widget.add_css_class ("md-in-container");
            widget.remove_css_class ("md-full-width");

            _content_clamp = new Adw.Clamp () {
                maximum_size = rem_to_layout_units (CONTENT_MAX_WIDTH_REM),
                tightening_threshold = rem_to_layout_units (CONTENT_MAX_WIDTH_REM),
                child = widget,
            };
            _content_clamp.add_css_class ("md-content-column");

            return _content_clamp;
        }

        _content_clamp = null;
        widget.add_css_class ("md-full-width");
        widget.remove_css_class ("md-in-container");

        return widget;
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
        var icon = new Gtk.Image.from_icon_name ("document-open-symbolic") {
            pixel_size = 48,
        };
        icon.add_css_class ("md-drop-zone-icon");

        var title = new Gtk.Label ("Open a Markdown file") {
            xalign = 0.5f,
        };
        title.add_css_class ("md-drop-zone-title");

        var hint = new Gtk.Label ("Drag and drop a .md file here, or use Open") {
            wrap = true,
            xalign = 0.5f,
        };
        hint.add_css_class ("md-empty");

        var open_button = new Gtk.Button.with_label ("Open File…");
        open_button.add_css_class ("pill");
        open_button.clicked.connect (show_open_file_dialog);

        var drop_zone = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            margin_top = 24,
            margin_bottom = 24,
            margin_start = 24,
            margin_end = 24,
        };
        drop_zone.add_css_class ("md-drop-zone");
        drop_zone.append (icon);
        drop_zone.append (title);
        drop_zone.append (hint);
        drop_zone.append (open_button);

        setup_file_drop (drop_zone);

        var container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            vexpand = true,
            hexpand = true,
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
        };
        container.add_css_class ("md-empty-state");
        container.append (drop_zone);

        return container;
    }

    private void show_open_file_dialog () {
        var filter = new Gtk.FileFilter () {
            name = "Markdown files",
        };
        filter.add_mime_type ("text/markdown");
        filter.add_mime_type ("text/x-markdown");
        filter.add_pattern ("*.md");
        filter.add_pattern ("*.markdown");
        filter.add_pattern ("*.mdown");
        filter.add_pattern ("*.mkd");

        var dialog = new Gtk.FileDialog () {
            title = "Open Markdown File",
            modal = true,
            default_filter = filter,
        };

        dialog.open.begin (this, null, (obj, res) => {
            try {
                var file = dialog.open.end (res);
                string? path = file.get_path ();
                if (path != null) {
                    open_file (path);
                }
            } catch (GLib.Error e) {
                if (e.matches (Gtk.DialogError.quark (), (int) Gtk.DialogError.CANCELLED) ||
                    e.matches (Gtk.DialogError.quark (), (int) Gtk.DialogError.DISMISSED)) {
                    return;
                }

                stderr.printf ("dastan: failed to open file: %s\n", e.message);
            }
        });
    }

    private void setup_file_drop (Gtk.Widget widget) {
        var file_drop = new Gtk.DropTarget (typeof (GLib.File), Gdk.DragAction.COPY);
        file_drop.enter.connect ((x, y) => {
            mark_drop_zone_active (widget, true);
            return Gdk.DragAction.COPY;
        });
        file_drop.leave.connect (() => {
            mark_drop_zone_active (widget, false);
        });
        file_drop.drop.connect ((value, x, y) => {
            mark_drop_zone_active (widget, false);
            return handle_dropped_file (value);
        });
        widget.add_controller (file_drop);

        var list_drop = new Gtk.DropTarget (typeof (Gdk.FileList), Gdk.DragAction.COPY);
        list_drop.enter.connect ((x, y) => {
            mark_drop_zone_active (widget, true);
            return Gdk.DragAction.COPY;
        });
        list_drop.leave.connect (() => {
            mark_drop_zone_active (widget, false);
        });
        list_drop.drop.connect ((value, x, y) => {
            mark_drop_zone_active (widget, false);
            return handle_dropped_file_list (value);
        });
        widget.add_controller (list_drop);
    }

    private void mark_drop_zone_active (Gtk.Widget widget, bool active) {
        Gtk.Widget? drop_zone = widget;
        if (!widget.has_css_class ("md-drop-zone")) {
            drop_zone = find_drop_zone (widget);
        }

        if (drop_zone == null) {
            return;
        }

        if (active) {
            drop_zone.add_css_class ("md-drop-zone-active");
        } else {
            drop_zone.remove_css_class ("md-drop-zone-active");
        }
    }

    private Gtk.Widget? find_drop_zone (Gtk.Widget root) {
        if (root.has_css_class ("md-drop-zone")) {
            return root;
        }

        var child = root.get_first_child ();
        while (child != null) {
            var found = find_drop_zone (child);
            if (found != null) {
                return found;
            }
            child = child.get_next_sibling ();
        }

        return null;
    }

    private void update_empty_state_layout () {
        if (_current_contents != null) {
            return;
        }

        var child = _scrolled.get_child ();
        if (child == null) {
            return;
        }

        var height = _scrolled.get_height ();
        if (height > 0) {
            child.height_request = height;
        }
    }

    private bool handle_dropped_file (GLib.Value value) {
        if (value.type () != typeof (GLib.File)) {
            return false;
        }

        var file = (GLib.File) value.get_object ();
        string? path = file.get_path ();
        return path != null && open_file (path);
    }

    private bool handle_dropped_file_list (GLib.Value value) {
        if (value.type () != typeof (Gdk.FileList)) {
            return false;
        }

        var files = ((Gdk.FileList) value.get_object ()).get_files ();
        foreach (unowned GLib.File file in files) {
            string? path = file.get_path ();
            if (path != null && open_file (path)) {
                return true;
            }
        }

        return false;
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
            GLib.Idle.add_once (() => {
                if (_settings_dialog != null) {
                    theme_widget_tree ((Gtk.Widget) _settings_dialog);
                }
            });
            return;
        }

        var settings_header = new Adw.HeaderBar ();

        var subtitle_label = new Gtk.Label ("Theme, zoom, and typography") {
            xalign = 0,
            hexpand = true,
        };
        subtitle_label.add_css_class ("dim-label");

        var theme_model = new Gtk.StringList (null);
        for (int i = 0; i < MARKDOWN_THEME_LABELS.length; i++) {
            theme_model.append (MARKDOWN_THEME_LABELS[i]);
        }

        _theme_dropdown = new Gtk.DropDown (theme_model, null) {
            valign = Gtk.Align.CENTER,
            selected = (uint) markdown_theme_index (_markdown_theme),
        };
        _theme_dropdown.add_css_class ("md-settings-theme-dropdown");
        _theme_dropdown.notify["selected"].connect (() => {
            if (_theme_dropdown == null) {
                return;
            }

            set_markdown_theme (markdown_theme_id ((int) _theme_dropdown.selected));
        });

        _theme_row = new Adw.ActionRow () {
            title = "Markdown theme",
        };
        _theme_row.add_suffix (_theme_dropdown);

        _container_row = new Adw.SwitchRow () {
            title = "Content container",
            subtitle = "Center text in a max-width reading column",
            active = _show_content_container,
        };
        _container_row.notify["active"].connect (() => {
            if (_container_row == null) {
                return;
            }

            set_show_content_container (_container_row.active);
        });

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

        var settings_body = new Gtk.Box (Gtk.Orientation.VERTICAL, 16) {
            margin_top = 12,
            margin_bottom = 24,
            margin_start = 12,
            margin_end = 12,
        };
        settings_body.add_css_class ("md-settings-content");
        apply_theme_class_to_widget (settings_body);
        settings_body.append (subtitle_label);
        settings_body.append (make_settings_section (
            "Theme",
            "Colors and typography for the whole window",
            _theme_row
        ));
        settings_body.append (make_settings_section (
            "Layout",
            "Reading area width and padding",
            _container_row
        ));
        settings_body.append (font_caption);
        settings_body.append (font_name_label);
        settings_body.append (font_detail_label);
        settings_body.append (font_preview_label);
        settings_body.append (zoom_caption);
        settings_body.append (zoom_controls);
        settings_body.append (reset_button);
        settings_body.append (hint);

        var settings_scrolled = new Gtk.ScrolledWindow () {
            vexpand = true,
            hexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vscrollbar_policy = Gtk.PolicyType.AUTOMATIC,
            min_content_width = SETTINGS_DIALOG_WIDTH,
            min_content_height = SETTINGS_DIALOG_HEIGHT - 48,
            child = settings_body,
        };

        var settings_toolbar = new Adw.ToolbarView () {
            width_request = SETTINGS_DIALOG_WIDTH,
            height_request = SETTINGS_DIALOG_HEIGHT,
        };
        settings_toolbar.add_top_bar (settings_header);
        settings_toolbar.content = settings_scrolled;

        var dialog = new Adw.Dialog () {
            title = "View Settings",
            child = settings_toolbar,
            can_close = true,
            follows_content_size = false,
            content_width = SETTINGS_DIALOG_WIDTH,
            content_height = SETTINGS_DIALOG_HEIGHT,
            presentation_mode = Adw.DialogPresentationMode.FLOATING,
        };
        ((Gtk.Widget) dialog).add_css_class ("md-settings-dialog");
        apply_theme_class_to_widget ((Gtk.Widget) dialog);
        _settings_dialog = dialog;

        dialog.closed.connect (() => {
            _settings_dialog = null;
            _zoom_value_label = null;
            _theme_row = null;
            _theme_dropdown = null;
            _container_row = null;
        });

        setup_settings_dialog_dismiss (dialog, settings_toolbar);

        dialog.present (this);
        GLib.Idle.add_once (() => {
            if (_settings_dialog != null) {
                theme_widget_tree ((Gtk.Widget) _settings_dialog);
            }
        });
    }

    private Gtk.Widget make_settings_section (string title, string description, Gtk.ListBoxRow row) {
        var section = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);

        var title_label = new Gtk.Label (title) {
            xalign = 0,
            hexpand = true,
        };
        title_label.add_css_class ("heading");
        section.append (title_label);

        var description_label = new Gtk.Label (description) {
            xalign = 0,
            hexpand = true,
            wrap = true,
        };
        description_label.add_css_class ("dim-label");
        section.append (description_label);

        var list = new Gtk.ListBox () {
            selection_mode = Gtk.SelectionMode.NONE,
        };
        list.add_css_class ("md-settings-list");
        list.append (row);
        section.append (list);

        return section;
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
            gtk_add_css_provider_for_display (
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
                MarkViewer.MarkdownRenderer.render (
                    _current_contents,
                    _font_scale,
                    MarkViewer.MarkdownTheme.palette (_markdown_theme).fg
                )
            );
            return;
        }

        _scrolled.child = wrap_content (make_empty_state ());
        update_empty_state_layout ();
    }

    private void load_styles () {
        var data_dir = MarkViewer.Config.data_dir ();
        load_stylesheet (Path.build_filename (data_dir, "markdown-themes.css"));
        load_stylesheet (Path.build_filename (data_dir, "markviewer.css"));
    }

    private void load_stylesheet (string css_path) {
        if (!FileUtils.test (css_path, FileTest.EXISTS)) {
            warning (@"Stylesheet not found: $css_path");
            return;
        }

        var provider = new Gtk.CssProvider ();
        provider.load_from_path (css_path);
        gtk_add_css_provider_for_display (
            Gdk.Display.get_default (),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }

    private void load_preferences () {
        _settings = new GLib.Settings ("io.github.markviewer");
        _markdown_theme = _settings.get_string ("markdown-theme");

        if (settings_has_key ("show-content-container")) {
            _show_content_container = _settings.get_boolean ("show-content-container");
        }

        if (markdown_theme_index (_markdown_theme) < 0) {
            _markdown_theme = "auto";
        }

        apply_markdown_theme_class ();
        apply_container_class ();
        apply_theme_css ();
    }

    private bool settings_has_key (string key) {
        if (_settings == null) {
            return false;
        }

        return _settings.settings_schema.has_key (key);
    }

    private void set_show_content_container (bool enabled) {
        if (_show_content_container == enabled) {
            return;
        }

        _show_content_container = enabled;
        apply_container_class ();

        if (_settings != null && settings_has_key ("show-content-container")) {
            _settings.set_boolean ("show-content-container", _show_content_container);
        }

        var scroll_y = _scrolled.get_vadjustment ().get_value ();
        refresh_content ();
        _scrolled.get_vadjustment ().set_value (scroll_y);
    }

    private void apply_container_class () {
        var widget = (Gtk.Widget) this;
        if (_show_content_container) {
            widget.add_css_class ("md-container-on");
            widget.remove_css_class ("md-container-off");
        } else {
            widget.add_css_class ("md-container-off");
            widget.remove_css_class ("md-container-on");
        }
    }

    private int markdown_theme_index (string theme_id) {
        for (int i = 0; i < MARKDOWN_THEME_IDS.length; i++) {
            if (MARKDOWN_THEME_IDS[i] == theme_id) {
                return i;
            }
        }

        return -1;
    }

    private string markdown_theme_id (int index) {
        if (index < 0 || index >= MARKDOWN_THEME_IDS.length) {
            return "auto";
        }

        return MARKDOWN_THEME_IDS[index];
    }

    private void set_markdown_theme (string theme_id) {
        if (markdown_theme_index (theme_id) < 0) {
            theme_id = "auto";
        }

        if (_markdown_theme == theme_id) {
            return;
        }

        _markdown_theme = theme_id;
        apply_markdown_theme_class ();
        apply_theme_css ();

        if (_settings != null) {
            _settings.set_string ("markdown-theme", _markdown_theme);
        }

        refresh_content ();
    }

    private void apply_markdown_theme_class () {
        apply_theme_class_to_widget ((Gtk.Widget) this);

        if (_settings_dialog != null) {
            theme_widget_tree ((Gtk.Widget) _settings_dialog);
        }
    }

    private void apply_theme_class_to_widget (Gtk.Widget widget) {
        for (int i = 0; i < MARKDOWN_THEME_IDS.length; i++) {
            widget.remove_css_class (@"md-theme-$(MARKDOWN_THEME_IDS[i])");
        }

        widget.add_css_class (@"md-theme-$_markdown_theme");
    }

    private void theme_widget_tree (Gtk.Widget widget) {
        apply_theme_class_to_widget (widget);

        var child = widget.get_first_child ();
        while (child != null) {
            theme_widget_tree (child);
            child = child.get_next_sibling ();
        }
    }

    private void apply_theme_css () {
        if (_theme_provider == null) {
            _theme_provider = new Gtk.CssProvider ();
            gtk_add_css_provider_for_display (
                Gdk.Display.get_default (),
                _theme_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_USER
            );
        }

        _theme_provider.load_from_string (MarkViewer.MarkdownTheme.css_for (_markdown_theme));
    }
}