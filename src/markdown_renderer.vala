namespace MarkViewer {
    public class MarkdownRenderer {
        private const double CODE_FONT_PT = 10.0;
        private static double _font_scale = 1.0;

        public static Gtk.Widget render (string markdown, double font_scale = 1.0) {
            _font_scale = font_scale;
            MathWidget.set_font_scale (font_scale);
            MathWidget.reset_for_document ();
            Cmark.gfm_core_extensions_ensure_registered ();

            var parser = Cmark.parser_new (0);
            attach_gfm_extensions (parser);
            var markdown_to_parse = MarkdownPreprocessor.preprocess (markdown);
            Cmark.parser_feed (parser, markdown_to_parse, markdown_to_parse.length);
            var document = Cmark.parser_finish (parser);
            Cmark.parser_free (parser);

            if (document == null) {
                var error_label = new Gtk.Label ("Failed to parse markdown.") {
                    wrap = true,
                    hexpand = true,
                    halign = Gtk.Align.FILL,
                };
                error_label.add_css_class ("markdown-body");
                error_label.add_css_class ("md-parse-error");
                return error_label;
            }

            var root = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
                halign = Gtk.Align.FILL,
                hexpand = true,
            };
            root.add_css_class ("markdown-body");
            apply_block_width (root);

            render_blocks (document, root);

            var document_text = plain_text (document);
            if (contains_rtl (document_text)) {
                root.add_css_class ("has-rtl");
            }

            Cmark.node_free (document);
            return root;
        }

        private static string node_type (Cmark.Node node) {
            return Cmark.node_get_type_string (node);
        }

        private static unowned string? node_literal (Cmark.Node node) {
            return Cmark.node_get_literal (node);
        }

        private static void render_blocks (Cmark.Node node, Gtk.Box parent) {
            for (unowned var child = Cmark.node_first_child (node); child != null; child = Cmark.node_next (child)) {
                render_block (child, parent);
            }
        }

        private static void render_block (Cmark.Node node, Gtk.Box parent) {
            switch (node_type (node)) {
                case "heading":
                    parent.append (make_heading (node));
                    break;
                case "paragraph":
                    parent.append (make_paragraph_label (node));
                    break;
                case "blockquote":
                    parent.append (make_blockquote (node));
                    break;
                case "list":
                    parent.append (make_list (node));
                    break;
                case "code_block":
                    parent.append (make_code_block (node));
                    break;
                case "thematic_break":
                    var rule = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
                    rule.add_css_class ("md-hr");
                    apply_block_width (rule);
                    parent.append (rule);
                    break;
                case "table":
                    parent.append (make_table (node));
                    break;
                case "html_block":
                    parent.append (make_plain_label (node_literal (node) ?? ""));
                    break;
                default:
                    if (Cmark.node_first_child (node) != null) {
                        render_blocks (node, parent);
                    }
                    break;
            }
        }

        private static Gtk.Label make_wrapped_label () {
            var label = new Gtk.Label (null) {
                wrap = true,
                selectable = true,
            };
            apply_block_width (label);
            return label;
        }

        private static Gtk.Widget make_heading (Cmark.Node node) {
            var level = Cmark.node_get_heading_level (node).clamp (1, 6);
            var text = plain_text (node);
            if (text.contains (MathRegistry.INLINE_PLACEHOLDER_PREFIX)) {
                var widget = MathWidget.make_inline_paragraph (text);
                widget.add_css_class (@"md-h$level");
                widget.add_css_class ("md-block");
                apply_block_width (widget);
                apply_rtl_if_needed (widget, text);
                return widget;
            }

            var label = make_wrapped_label ();
            set_label_markup (label, inline_markup (node), text);
            label.add_css_class (@"md-h$level");
            apply_rtl_if_needed (label, text);
            return label;
        }

        private static Gtk.Widget make_paragraph_label (Cmark.Node node) {
            var text = plain_text (node);
            var trimmed = text.strip ();
            if (MathRegistry.is_block_placeholder (trimmed)) {
                var formula_id = MathRegistry.parse_placeholder_id (trimmed);
                var latex = MathRegistry.get_block (formula_id);
                if (latex != null) {
                    var widget = MathWidget.make_block (latex);
                    widget.add_css_class ("md-block");
                    widget.add_css_class ("md-paragraph");
                    apply_block_width (widget);
                    return widget;
                }
            }

            if (text.contains (MathRegistry.INLINE_PLACEHOLDER_PREFIX)) {
                var widget = MathWidget.make_inline_paragraph (text);
                widget.add_css_class ("md-block");
                widget.add_css_class ("md-paragraph");
                apply_block_width (widget);
                apply_rtl_if_needed (widget, text);
                return widget;
            }

            var label = make_wrapped_label ();
            set_label_markup (label, inline_markup (node), text);
            label.add_css_class ("md-paragraph");
            apply_rtl_if_needed (label, text);
            return label;
        }

        private static Gtk.Widget make_list_paragraph_label (Cmark.Node node) {
            var text = plain_text (node);
            if (text.contains (MathRegistry.INLINE_PLACEHOLDER_PREFIX)) {
                var widget = MathWidget.make_inline_paragraph (text);
                widget.add_css_class ("md-paragraph");
                widget.add_css_class ("md-list-paragraph");
                apply_fill_width (widget);
                apply_rtl_if_needed (widget, text);
                return widget;
            }

            var label = new Gtk.Label (null) {
                wrap = true,
                selectable = true,
                valign = Gtk.Align.START,
                vexpand = false,
                hexpand = true,
                halign = Gtk.Align.FILL,
                yalign = 0,
            };
            set_label_markup (label, inline_markup (node), text);
            label.add_css_class ("md-paragraph");
            label.add_css_class ("md-list-paragraph");
            apply_rtl_if_needed (label, text);
            return label;
        }

        private static Gtk.Label make_plain_label (string text) {
            var label = make_wrapped_label ();
            label.label = text;
            label.add_css_class ("md-paragraph");
            apply_rtl_if_needed (label, text);
            return label;
        }

        private static Gtk.Widget make_blockquote (Cmark.Node node) {
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            box.add_css_class ("md-blockquote");
            apply_block_width (box);
            render_blocks (node, box);
            apply_rtl_if_needed (box, plain_text (node));
            return box;
        }

        private static Gtk.Widget make_list (Cmark.Node node) {
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            box.add_css_class ("md-list");
            apply_block_width (box);
            var ordered = Cmark.node_get_list_type (node) == Cmark.ListType.ORDERED_LIST;
            var counter = Cmark.node_get_list_start (node);

            for (unowned var item = Cmark.node_first_child (node); item != null; item = Cmark.node_next (item)) {
                box.append (make_list_item (item, ordered, counter));
                if (ordered) {
                    counter++;
                }
            }

            return box;
        }

        private static void attach_gfm_extensions (Cmark.Parser parser) {
            string[] extensions = {
                "table",
                "strikethrough",
                "autolink",
                "tagfilter",
                "tasklist",
            };

            foreach (var name in extensions) {
                var extension = Cmark.find_syntax_extension (name);
                if (extension != null) {
                    Cmark.parser_attach_syntax_extension (parser, extension);
                }
            }
        }

        private static Gtk.Widget make_list_item (Cmark.Node item, bool ordered, int number) {
            var row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
                valign = Gtk.Align.START,
            };
            row.add_css_class ("md-list-item");
            apply_fill_width (row);

            string marker;
            if (ordered) {
                marker = @"$number.";
            } else if (Cmark.extensions_get_tasklist_item_checked (item)) {
                marker = "☑";
            } else if (item_has_tasklist_marker (item)) {
                marker = "☐";
            } else {
                marker = "•";
            }

            var marker_label = new Gtk.Label (marker) {
                valign = Gtk.Align.START,
                vexpand = false,
                hexpand = false,
                xalign = ordered ? 1.0f : 0.0f,
                yalign = 0,
                wrap = false,
            };
            marker_label.add_css_class ("md-list-marker");
            if (ordered) {
                marker_label.add_css_class ("md-list-marker-ordered");
            } else {
                marker_label.add_css_class ("md-list-marker-bullet");
            }
            row.append (marker_label);

            var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
                hexpand = true,
                valign = Gtk.Align.START,
                vexpand = false,
            };

            for (unowned var child = Cmark.node_first_child (item); child != null; child = Cmark.node_next (child)) {
                if (node_type (child) == "paragraph") {
                    content.append (make_list_paragraph_label (child));
                } else {
                    render_block (child, content);
                }
            }

            row.append (content);
            apply_rtl_if_needed (content, plain_text (item));
            apply_rtl_if_needed (row, plain_text (item));
            return row;
        }

        private static bool item_has_tasklist_marker (Cmark.Node item) {
            for (unowned var child = Cmark.node_first_child (item); child != null; child = Cmark.node_next (child)) {
                if (node_type (child) == "paragraph") {
                    var text = plain_text (child);
                    if (text.has_prefix ("[ ]") || text.has_prefix ("[x]") || text.has_prefix ("[X]")) {
                        return true;
                    }
                }
            }
            return false;
        }

        private static Gtk.Widget make_code_block (Cmark.Node node) {
            var text_view = new Gtk.TextView () {
                editable = false,
                cursor_visible = true,
                can_focus = true,
                monospace = true,
                wrap_mode = Gtk.WrapMode.NONE,
                left_margin = 0,
                right_margin = 0,
                top_margin = 0,
                bottom_margin = 0,
                valign = Gtk.Align.START,
                vexpand = false,
                hexpand = true,
                halign = Gtk.Align.FILL,
            };
            text_view.buffer.text = force_ltr_code_text (node_literal (node) ?? "");
            text_view.add_css_class ("md-code-block");
            apply_code_text_view (text_view);

            var wrap = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
                halign = Gtk.Align.FILL,
                hexpand = true,
            };
            var scrolled = new Gtk.ScrolledWindow () {
                hscrollbar_policy = Gtk.PolicyType.AUTOMATIC,
                vscrollbar_policy = Gtk.PolicyType.NEVER,
                propagate_natural_height = true,
                propagate_natural_width = false,
                valign = Gtk.Align.START,
                vexpand = false,
                hexpand = true,
                halign = Gtk.Align.FILL,
                child = text_view,
            };
            scrolled.add_css_class ("md-code-scroll");

            wrap.add_css_class ("md-code-wrap");
            apply_block_width (wrap);
            apply_code_container (wrap);
            apply_code_container (scrolled);
            wrap.append (scrolled);

            return wrap;
        }

        private static void decorate_table_cell_box (
            Gtk.Widget cell_box,
            bool is_header,
            bool is_last_row,
            bool is_last_column
        ) {
            cell_box.add_css_class ("md-table-cell");
            if (is_header) {
                cell_box.add_css_class ("md-table-header");
            }
            if (is_last_row) {
                cell_box.add_css_class ("md-table-row-last");
            }
            if (is_last_column) {
                cell_box.add_css_class ("md-table-col-last");
            }
        }

        private static Gtk.Widget make_table_cell (
            Cmark.Node cell,
            bool is_header,
            bool is_last_row,
            bool is_last_column
        ) {
            var text = plain_text (cell);
            var cell_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
                valign = Gtk.Align.START,
                vexpand = false,
                hexpand = true,
                halign = Gtk.Align.FILL,
            };
            apply_ltr (cell_box);
            decorate_table_cell_box (cell_box, is_header, is_last_row, is_last_column);

            if (text.contains (MathRegistry.INLINE_PLACEHOLDER_PREFIX)) {
                var widget = MathWidget.make_inline_paragraph (text);
                apply_fill_width (widget);
                apply_table_cell_text (widget, text);
                cell_box.append (widget);
                return cell_box;
            }

            var label = new Gtk.Label (null) {
                wrap = true,
                selectable = true,
                valign = Gtk.Align.START,
                vexpand = false,
                hexpand = true,
                halign = Gtk.Align.FILL,
                xalign = 0,
            };
            label.set_wrap_mode (Pango.WrapMode.WORD_CHAR);
            set_label_markup (label, inline_markup (cell, true), text);
            apply_table_cell_text (label, text);
            cell_box.append (label);
            return cell_box;
        }

        private static void set_label_markup (Gtk.Label label, string markup, string plain_fallback) {
            if (markup.length == 0) {
                label.label = plain_fallback;
                return;
            }

            try {
                label.set_markup (markup);
            } catch (MarkupError e) {
                label.label = plain_fallback;
                return;
            }

            if (label.label.length == 0 && plain_fallback.length > 0) {
                label.label = plain_fallback;
            }
        }

        private static Gtk.Widget make_table (Cmark.Node node) {
            int row_count = 0;
            int column_count = 0;
            for (unowned var row = Cmark.node_first_child (node); row != null; row = Cmark.node_next (row)) {
                row_count++;
                if (column_count == 0) {
                    for (unowned var cell = Cmark.node_first_child (row); cell != null; cell = Cmark.node_next (cell)) {
                        column_count++;
                    }
                }
            }

            var grid = new Gtk.Grid () {
                column_spacing = 0,
                row_spacing = 0,
                column_homogeneous = true,
                valign = Gtk.Align.START,
                vexpand = false,
                hexpand = true,
                halign = Gtk.Align.FILL,
            };
            apply_ltr (grid);

            int row_index = 0;
            for (unowned var row = Cmark.node_first_child (node); row != null; row = Cmark.node_next (row)) {
                int column_index = 0;
                bool is_header = node_type (row) == "table_header";
                bool is_last_row = row_index == row_count - 1;

                for (unowned var cell = Cmark.node_first_child (row); cell != null; cell = Cmark.node_next (cell)) {
                    bool is_last_column = column_index == column_count - 1;
                    var cell_widget = make_table_cell (cell, is_header, is_last_row, is_last_column);
                    grid.attach (cell_widget, column_index, row_index, 1, 1);
                    column_index++;
                }

                row_index++;
            }

            var table_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
                valign = Gtk.Align.START,
                vexpand = false,
                hexpand = true,
                halign = Gtk.Align.FILL,
            };
            table_box.add_css_class ("md-table");
            table_box.append (grid);

            var scrolled = new Gtk.ScrolledWindow () {
                hscrollbar_policy = Gtk.PolicyType.AUTOMATIC,
                vscrollbar_policy = Gtk.PolicyType.NEVER,
                propagate_natural_height = true,
                propagate_natural_width = false,
                valign = Gtk.Align.START,
                vexpand = false,
                hexpand = true,
                halign = Gtk.Align.FILL,
                child = table_box,
            };
            scrolled.add_css_class ("md-table-scroll");
            apply_block_width (scrolled);
            return scrolled;
        }

        private static string inline_markup (Cmark.Node node, bool isolate_inline_code = false) {
            var builder = new StringBuilder ();
            build_inline_markup (node, builder, isolate_inline_code);
            return builder.str;
        }

        private static void build_inline_markup (
            Cmark.Node node,
            StringBuilder builder,
            bool isolate_inline_code
        ) {
            for (unowned var child = Cmark.node_first_child (node); child != null; child = Cmark.node_next (child)) {
                append_inline_markup (child, builder, isolate_inline_code);
            }
        }

        private static void append_inline_markup (
            Cmark.Node node,
            StringBuilder builder,
            bool isolate_inline_code
        ) {
            switch (node_type (node)) {
                case "text":
                    builder.append (Markup.escape_text (node_literal (node) ?? ""));
                    break;
                case "softbreak":
                    builder.append ("\n");
                    break;
                case "linebreak":
                    builder.append ("\n");
                    break;
                case "code":
                    var code_text = Markup.escape_text (node_literal (node) ?? "");
                    if (isolate_inline_code) {
                        code_text = wrap_ltr_isolate (code_text);
                    }
                    builder.append (@"<span font_family=\"Noto Sans Mono\" font_size=\"$(code_font_size_pango ())\"><tt>$code_text</tt></span>");
                    break;
                case "emph":
                    builder.append ("<i>");
                    build_inline_markup (node, builder, isolate_inline_code);
                    builder.append ("</i>");
                    break;
                case "strong":
                    builder.append ("<b>");
                    build_inline_markup (node, builder, isolate_inline_code);
                    builder.append ("</b>");
                    break;
                case "strikethrough":
                    builder.append ("<s>");
                    build_inline_markup (node, builder, isolate_inline_code);
                    builder.append ("</s>");
                    break;
                case "link":
                    var url = Markup.escape_text (Cmark.node_get_url (node) ?? "");
                    builder.append (@"<a href=\"$url\">");
                    build_inline_markup (node, builder, isolate_inline_code);
                    builder.append ("</a>");
                    break;
                case "image":
                    var alt = Markup.escape_text (plain_text (node));
                    builder.append ("<i>[");
                    builder.append (alt);
                    builder.append ("]</i>");
                    break;
                default:
                    if (Cmark.node_first_child (node) != null) {
                        build_inline_markup (node, builder, isolate_inline_code);
                    } else if (node_literal (node) != null) {
                        builder.append (Markup.escape_text (node_literal (node)));
                    }
                    break;
            }
        }

        private static string plain_text (Cmark.Node node) {
            var builder = new StringBuilder ();
            collect_plain_text (node, builder);
            return builder.str;
        }

        private static void collect_plain_text (Cmark.Node node, StringBuilder builder) {
            var literal = node_literal (node);
            if (literal != null) {
                builder.append (literal);
            }

            for (unowned var child = Cmark.node_first_child (node); child != null; child = Cmark.node_next (child)) {
                collect_plain_text (child, builder);
            }
        }

        private static bool contains_rtl (string text) {
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

        private static string wrap_ltr_isolate (string text) {
            if (text.length == 0) {
                return text;
            }

            const string LRI = "\u2066";
            const string PDI = "\u2069";
            return LRI + text + PDI;
        }

        private static string force_ltr_code_text (string text) {
            if (text.length == 0) {
                return text;
            }

            const string LRO = "\u202d";
            const string PDF = "\u202c";
            const string LRM = "\u200e";
            var lines = text.split ("\n", -1);
            var builder = new StringBuilder ();
            builder.append (LRO);

            for (int i = 0; i < lines.length; i++) {
                if (i > 0) {
                    builder.append ("\n");
                }
                builder.append (LRM);
                builder.append (lines[i]);
            }

            builder.append (PDF);
            return builder.str;
        }

        private static int code_font_size_pt () {
            return (int) (CODE_FONT_PT * _font_scale + 0.5);
        }

        private static string code_font_name () {
            return @"Noto Sans Mono $(code_font_size_pt ())";
        }

        private static int code_font_size_pango () {
            return (int) (CODE_FONT_PT * _font_scale * Pango.SCALE + 0.5);
        }

        private static void apply_fill_width (Gtk.Widget widget) {
            widget.hexpand = true;
            widget.halign = Gtk.Align.FILL;
        }

        private static void apply_block_width (Gtk.Widget widget) {
            apply_fill_width (widget);
            widget.add_css_class ("md-block");
        }

        private static void apply_code_container (Gtk.Widget widget) {
            widget.set_direction (Gtk.TextDirection.LTR);
            apply_ltr (widget);
        }

        private static void apply_code_text_view (Gtk.TextView text_view) {
            text_view.set_direction (Gtk.TextDirection.LTR);
            text_view.justification = Gtk.Justification.LEFT;
            text_view.can_focus = true;

            var buffer = text_view.buffer;
            Gtk.TextIter start_iter;
            Gtk.TextIter end_iter;
            buffer.get_bounds (out start_iter, out end_iter);

            var tag = buffer.create_tag ("md-code",
                "font", code_font_name (),
                "direction", Gtk.TextDirection.LTR);
            buffer.apply_tag (tag, start_iter, end_iter);
        }

        private static void apply_ltr (Gtk.Widget widget) {
            widget.set_direction (Gtk.TextDirection.LTR);

            var child = widget.get_first_child ();
            while (child != null) {
                apply_ltr (child);
                child = child.get_next_sibling ();
            }
        }

        private static void apply_table_cell_text (Gtk.Widget widget, string? text) {
            if (text == null || !contains_rtl (text)) {
                if (widget is Gtk.Label) {
                    var label = (Gtk.Label) widget;
                    apply_ltr (widget);
                    label.xalign = 0;
                    label.justify = Gtk.Justification.LEFT;
                } else {
                    apply_ltr (widget);
                }
                return;
            }

            widget.set_direction (Gtk.TextDirection.RTL);

            if (widget is Gtk.Label) {
                var label = (Gtk.Label) widget;
                label.xalign = 0;
                label.justify = Gtk.Justification.LEFT;
            }
        }

        private static void apply_rtl_if_needed (Gtk.Widget widget, string? text) {
            if (text == null || !contains_rtl (text)) {
                if (widget is Gtk.Label) {
                    var label = (Gtk.Label) widget;
                    apply_ltr (widget);
                    label.xalign = 0;
                    label.justify = Gtk.Justification.LEFT;
                }
                return;
            }

            widget.set_direction (Gtk.TextDirection.RTL);

            if (widget is Gtk.Label) {
                var label = (Gtk.Label) widget;
                // GTK mirrors xalign for RTL widgets; LEFT justify follows Pango's
                // logical start edge, which is the physical right for RTL text.
                label.xalign = 0;
                label.justify = Gtk.Justification.LEFT;
            }
        }
    }
}
