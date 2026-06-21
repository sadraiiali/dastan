namespace MarkViewer {
    public class MarkdownPreprocessor {
        public static string preprocess (string markdown) {
            var result = protect_math (markdown);
            result = normalize_blockquote_lists (result);
            result = normalize_list_markers (result);
            return result;
        }

        private static string protect_math (string markdown) {
            MathRegistry.reset ();

            var builder = new StringBuilder ();
            bool in_fence = false;

            for (int line_start = 0; line_start <= markdown.length;) {
                int line_end = markdown.index_of_char ('\n', line_start);
                if (line_end < 0) {
                    line_end = markdown.length;
                }

                var line = markdown.substring (line_start, line_end - line_start);
                var trimmed = line.strip ();

                if (trimmed.has_prefix ("```")) {
                    in_fence = !in_fence;
                    builder.append (line);
                } else if (in_fence) {
                    builder.append (line);
                } else {
                    builder.append (protect_math_in_text (line));
                }

                if (line_end >= markdown.length) {
                    break;
                }

                builder.append_c ('\n');
                line_start = line_end + 1;
            }

            return protect_block_math (builder.str);
        }

        private static string protect_block_math (string text) {
            var builder = new StringBuilder ();
            int pos = 0;

            while (pos < text.length) {
                if (text_has_prefix_at (text, "\\[", pos)) {
                    int end = text.index_of ("\\]", pos + 2);
                    if (end >= 0) {
                        var latex = text.substring (pos + 2, end - pos - 2).strip ();
                        var id = MathRegistry.register_block (latex);
                        builder.append ("\n\n");
                        builder.append (MathRegistry.block_placeholder (id));
                        builder.append ("\n\n");
                        pos = end + 2;
                        continue;
                    }
                }

                if (text_has_prefix_at (text, "$$", pos)) {
                    int end = text.index_of ("$$", pos + 2);
                    if (end >= 0) {
                        var latex = text.substring (pos + 2, end - pos - 2).strip ();
                        var id = MathRegistry.register_block (latex);
                        builder.append ("\n\n");
                        builder.append (MathRegistry.block_placeholder (id));
                        builder.append ("\n\n");
                        pos = end + 2;
                        continue;
                    }
                }

                builder.append_c (text[pos]);
                pos++;
            }

            return builder.str;
        }

        private static string protect_math_in_text (string line) {
            var builder = new StringBuilder ();
            int pos = 0;

            while (pos < line.length) {
                if (text_has_prefix_at (line, "\\(", pos)) {
                    int end = line.index_of ("\\)", pos + 2);
                    if (end >= 0) {
                        var latex = line.substring (pos + 2, end - pos - 2).strip ();
                        if (latex.length > 0) {
                            var id = MathRegistry.register_inline (latex);
                            builder.append (MathRegistry.inline_placeholder (id));
                            pos = end + 2;
                            continue;
                        }
                    }
                }

                if (line[pos] == '$' && !is_escaped (line, pos) && !text_has_prefix_at (line, "$$", pos)) {
                    var latex = try_extract_inline_dollar (line, ref pos);
                    if (latex != null) {
                        var id = MathRegistry.register_inline (latex);
                        builder.append (MathRegistry.inline_placeholder (id));
                        continue;
                    }
                }

                builder.append_c (line[pos]);
                pos++;
            }

            return builder.str;
        }

        private static bool text_has_prefix_at (string text, string prefix, int pos) {
            if (pos + prefix.length > text.length) {
                return false;
            }
            return text.substring (pos, prefix.length) == prefix;
        }

        private static bool is_escaped (string text, int pos) {
            return pos > 0 && text[pos - 1] == '\\';
        }

        private static string? try_extract_inline_dollar (string line, ref int pos) {
            int start = pos + 1;
            if (start >= line.length) {
                return null;
            }

            if (line[start] == ' ') {
                return null;
            }

            int end = start;
            while (end < line.length) {
                if (line[end] == '$' && !is_escaped (line, end)) {
                    if (end == start || line[end - 1] == ' ') {
                        return null;
                    }

                    var latex = line.substring (start, end - start);
                    pos = end + 1;
                    return latex;
                }
                end++;
            }

            return null;
        }

        private static string normalize_digit (unichar character) {
            switch (character) {
                case '۰': return "0";
                case '۱': return "1";
                case '۲': return "2";
                case '۳': return "3";
                case '۴': return "4";
                case '۵': return "5";
                case '۶': return "6";
                case '۷': return "7";
                case '۸': return "8";
                case '۹': return "9";
                case '٠': return "0";
                case '١': return "1";
                case '٢': return "2";
                case '٣': return "3";
                case '٤': return "4";
                case '٥': return "5";
                case '٦': return "6";
                case '٧': return "7";
                case '٨': return "8";
                case '٩': return "9";
                default: return character.to_string ();
            }
        }

        private static string normalize_list_markers (string markdown) {
            var builder = new StringBuilder ();
            var lines = markdown.split ("\n", -1);

            for (int i = 0; i < lines.length; i++) {
                builder.append (normalize_list_marker_line (lines[i]));
                if (i + 1 < lines.length) {
                    builder.append_c ('\n');
                }
            }

            return builder.str;
        }

        private static string normalize_list_marker_line (string line) {
            int pos = 0;
            int len = line.length;

            while (pos < len && line[pos] == ' ') {
                pos++;
            }

            int digit_start = pos;
            var digits = new StringBuilder ();

            while (pos < len) {
                unichar character = line[pos];
                if ((character >= '۰' && character <= '۹') || (character >= '٠' && character <= '٩')) {
                    digits.append (normalize_digit (character));
                    pos++;
                    continue;
                }
                break;
            }

            if (digits.len == 0 || pos >= len) {
                return line;
            }

            unichar punctuation = line[pos];
            if (punctuation != '.' && punctuation != ')') {
                return line;
            }
            pos++;

            if (pos >= len || line[pos] != ' ') {
                return line;
            }

            var punct = punctuation.to_string ();
            return @"$(line.substring(0, digit_start))$(digits.str)$punct$(line.substring(pos))";
        }

        private static string normalize_blockquote_lists (string markdown) {
            var builder = new StringBuilder ();
            var lines = markdown.split ("\n", -1);

            for (int i = 0; i < lines.length; i++) {
                var line = lines[i];
                if (line.has_prefix ("> -- ")) {
                    builder.append ("> - ");
                    builder.append (line.offset (5));
                } else {
                    builder.append (line);
                }

                if (i + 1 < lines.length) {
                    builder.append_c ('\n');
                }
            }

            return builder.str;
        }
    }
}