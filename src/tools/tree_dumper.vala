namespace MarkViewer {
    public class TreeDumper {
        public static string dump_yaml (string markdown, string? source_path = null) {
            Cmark.gfm_core_extensions_ensure_registered ();

            var parser = Cmark.parser_new (0);
            attach_gfm_extensions (parser);

            var markdown_to_parse = MarkdownPreprocessor.preprocess (markdown);
            Cmark.parser_feed (parser, markdown_to_parse, markdown_to_parse.length);
            var document = Cmark.parser_finish (parser);
            Cmark.parser_free (parser);

            if (document == null) {
                return "error: failed to parse markdown\n";
            }

            var yaml = new StringBuilder ();
            yaml.append ("# encoding: utf-16le (file) / utf-8 (logical)\n");
            yaml.append ("# MarkViewer AST dump with text direction per node\n");
            yaml.append ("# direction: ltr | rtl | mixed (document root only)\n");
            yaml.append ("# Code blocks and tables are always tagged ltr.\n");
            yaml.append ("# Persian/Arabic text uses YAML block literals (|-) for correct UTF-8 display.\n");
            if (source_path != null) {
                yaml.append_printf ("source: %s\n", escape_yaml_string (source_path));
            }
            yaml.append ("tree:\n");
            dump_node (document, yaml, 1, true);

            Cmark.node_free (document);
            return yaml.str;
        }

        private static void attach_gfm_extensions (Cmark.Parser parser) {
            string[] extensions = {
                "table",
                "strikethrough",
                "autolink",
                "tagfilter",
                "tasklist",
            };

            for (int i = 0; i < extensions.length; i++) {
                var extension = Cmark.find_syntax_extension (extensions[i]);
                if (extension != null) {
                    Cmark.parser_attach_syntax_extension (parser, extension);
                }
            }
        }

        private static void dump_node (Cmark.Node node, StringBuilder yaml, int depth, bool is_root) {
            var pad = indent (depth);
            var child_pad = indent (depth + 1);
            var type = node_type (node);
            var text = plain_text (node);
            var direction = resolve_direction (node, type, text);

            if (!is_root) {
                yaml.append_printf ("%s- type: %s\n", pad, type);
            } else {
                yaml.append_printf ("%s  type: %s\n", pad, type);
            }

            yaml.append_printf ("%s  direction: %s\n", is_root ? pad : child_pad, direction);

            if (type == "heading") {
                yaml.append_printf ("%s  level: %d\n", is_root ? pad : child_pad,
                    Cmark.node_get_heading_level (node).clamp (1, 6));
            }

            if (type == "link") {
                var url = Cmark.node_get_url (node);
                if (url != null) {
                    yaml.append_printf ("%s  url: %s\n", is_root ? pad : child_pad,
                        escape_yaml_string (url));
                }
            }

            if (type == "code_block") {
                var info = Cmark.node_get_fence_info (node);
                if (info != null && info.length > 0) {
                    yaml.append_printf ("%s  info: %s\n", is_root ? pad : child_pad,
                        escape_yaml_string (info));
                }
            }

            var preview = text_preview (node, type, text);
            if (preview != null) {
                var field_pad = (is_root ? pad : child_pad) + "  ";
                append_text_field (yaml, field_pad, preview);
            }

            var child = Cmark.node_first_child (node);
            if (child != null) {
                yaml.append_printf ("%s  children:\n", is_root ? pad : child_pad);
                for (; child != null; child = Cmark.node_next (child)) {
                    dump_node (child, yaml, depth + (is_root ? 1 : 2), false);
                }
            }
        }

        private static string resolve_direction (Cmark.Node node, string type, string text) {
            if (type == "document") {
                return document_direction (node);
            }

            if (is_forced_ltr (type)) {
                return "ltr";
            }

            return contains_rtl (text) ? "rtl" : "ltr";
        }

        private static string document_direction (Cmark.Node node) {
            bool has_rtl = false;
            bool has_ltr = false;
            collect_document_direction (node, ref has_rtl, ref has_ltr);

            if (has_rtl && has_ltr) {
                return "mixed";
            }
            if (has_rtl) {
                return "rtl";
            }
            return "ltr";
        }

        private static void collect_document_direction (Cmark.Node node, ref bool has_rtl, ref bool has_ltr) {
            var type = node_type (node);

            if (type != "document" && !is_forced_ltr (type)) {
                var text = plain_text (node);
                if (text.length > 0) {
                    if (contains_rtl (text)) {
                        has_rtl = true;
                    } else if (has_letters (text)) {
                        has_ltr = true;
                    }
                }
            }

            for (unowned var child = Cmark.node_first_child (node); child != null; child = Cmark.node_next (child)) {
                collect_document_direction (child, ref has_rtl, ref has_ltr);
            }
        }

        private static bool is_forced_ltr (string type) {
            return type == "code_block"
                || type == "table"
                || type == "table_header"
                || type == "table_row"
                || type == "table_cell"
                || type == "code";
        }

        private static bool has_letters (string text) {
            for (int i = 0; i < text.char_count (); i++) {
                if (text.get_char (text.index_of_nth_char (i)).isalpha ()) {
                    return true;
                }
            }
            return false;
        }

        private static string? text_preview (Cmark.Node node, string type, string text) {
            if (type == "text" || type == "code") {
                return trim_preview (text);
            }

            if (type == "paragraph" || type == "heading" || type == "code_block") {
                return trim_preview (text);
            }

            var literal = node_literal (node);
            if (literal != null && literal.length > 0 && type != "document") {
                return trim_preview (literal);
            }

            return null;
        }

        private static void append_text_field (StringBuilder yaml, string field_pad, string text) {
            if (text.length == 0) {
                yaml.append_printf ("%stext: \"\"\n", field_pad);
                return;
            }

            yaml.append_printf ("%stext: |-\n", field_pad);
            var line_pad = field_pad + "  ";
            var lines = text.split ("\n", -1);
            for (int i = 0; i < lines.length; i++) {
                yaml.append_printf ("%s%s\n", line_pad, lines[i]);
            }
        }

        private static string trim_preview (string text) {
            var trimmed = text.strip ();
            const int max_chars = 120;
            if (trimmed.char_count () <= max_chars) {
                return trimmed;
            }
            return trimmed.substring (0, trimmed.index_of_nth_char (max_chars)) + "…";
        }

        private static string indent (int depth) {
            var pad = new StringBuilder ();
            for (int i = 0; i < depth; i++) {
                pad.append ("  ");
            }
            return pad.str;
        }

        private static string escape_yaml_string (string value) {
            var builder = new StringBuilder ("\"");
            for (int i = 0; i < value.char_count (); i++) {
                unichar ch = value.get_char (value.index_of_nth_char (i));
                switch (ch) {
                    case '"':
                        builder.append ("\\\"");
                        break;
                    case '\\':
                        builder.append ("\\\\");
                        break;
                    case '\n':
                        builder.append ("\\n");
                        break;
                    case '\r':
                        builder.append ("\\r");
                        break;
                    case '\t':
                        builder.append ("\\t");
                        break;
                    default:
                        builder.append_unichar (ch);
                        break;
                }
            }
            builder.append_c ('"');
            return builder.str;
        }

        private static string node_type (Cmark.Node node) {
            return Cmark.node_get_type_string (node);
        }

        private static unowned string? node_literal (Cmark.Node node) {
            return Cmark.node_get_literal (node);
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
    }
}

public class DumpTree {
    public static int main (string[] args) {
        if (args.length < 2) {
            stderr.printf ("usage: %s [--utf8] <markdown-file> [output.yml]\n", args[0]);
            stderr.printf ("  default file output: UTF-16LE with BOM (Persian-friendly in editors)\n");
            stderr.printf ("  --utf8: write UTF-8 without BOM instead\n");
            return 1;
        }

        bool use_utf8 = false;
        int path_index = 1;

        if (args.length > path_index && args[path_index] == "--utf8") {
            use_utf8 = true;
            path_index++;
        }

        if (path_index >= args.length) {
            stderr.printf ("dump-tree: missing markdown file path\n");
            return 1;
        }

        string? contents = null;
        try {
            FileUtils.get_contents (args[path_index], out contents);
        } catch (FileError e) {
            stderr.printf ("dump-tree: %s\n", e.message);
            return 1;
        }

        var yaml = MarkViewer.TreeDumper.dump_yaml (contents, args[path_index]);

        if (path_index + 1 < args.length) {
            var output_path = args[path_index + 1];
            if (!write_output_file (output_path, yaml, use_utf8)) {
                return 1;
            }
        } else {
            print ("%s", yaml);
        }

        return 0;
    }

    private static bool write_output_file (string path, string text, bool use_utf8) {
        try {
            uint8[] data = use_utf8 ? (uint8[]) text.to_utf8 () : utf8_to_utf16le (text);
            write_bytes (path, data);
            return true;
        } catch (GLib.Error e) {
            stderr.printf ("dump-tree: %s\n", e.message);
            return false;
        }
    }

    private static uint8[] utf8_to_utf16le (string text) {
        var data = new ByteArray ();
        data.append ({ 0xFF, 0xFE });

        for (int i = 0; i < text.char_count (); i++) {
            unichar codepoint = text.get_char (text.index_of_nth_char (i));
            append_utf16le_codeunit (data, codepoint);
        }

        return data.data;
    }

    private static void append_utf16le_codeunit (ByteArray data, unichar codepoint) {
        if (codepoint < 0x10000) {
            data.append ({ (uint8) (codepoint & 0xFF), (uint8) ((codepoint >> 8) & 0xFF) });
            return;
        }

        unichar offset = codepoint - 0x10000;
        unichar high = 0xD800 + ((offset >> 10) & 0x3FF);
        unichar low = 0xDC00 + (offset & 0x3FF);
        append_utf16le_codeunit (data, high);
        append_utf16le_codeunit (data, low);
    }

    private static void write_bytes (string path, uint8[] data) throws GLib.Error {
        var file = File.new_for_path (path);
        OutputStream output = file.replace (null, false, FileCreateFlags.REPLACE_DESTINATION, null);
        output.write (data);
        output.close ();
    }
}