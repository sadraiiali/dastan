namespace MarkViewer {
    public class MathRegistry {
        private static string[] _block_formulas = {};
        private static string[] _inline_formulas = {};

        public const string BLOCK_PLACEHOLDER_PREFIX = "⟦BLOCKMATH:";
        public const string INLINE_PLACEHOLDER_PREFIX = "⟦INLINEMATH:";
        public const string PLACEHOLDER_SUFFIX = "⟧";

        public static void reset () {
            _block_formulas = {};
            _inline_formulas = {};
        }

        public static int register_block (string latex) {
            int id = _block_formulas.length;
            _block_formulas += latex;
            return id;
        }

        public static int register_inline (string latex) {
            int id = _inline_formulas.length;
            _inline_formulas += latex;
            return id;
        }

        public static string? get_block (int id) {
            if (id < 0 || id >= _block_formulas.length) {
                return null;
            }
            return _block_formulas[id];
        }

        public static string? get_inline (int id) {
            if (id < 0 || id >= _inline_formulas.length) {
                return null;
            }
            return _inline_formulas[id];
        }

        public static string block_placeholder (int id) {
            return @"$(BLOCK_PLACEHOLDER_PREFIX)$(id)$(PLACEHOLDER_SUFFIX)";
        }

        public static string inline_placeholder (int id) {
            return @"$(INLINE_PLACEHOLDER_PREFIX)$(id)$(PLACEHOLDER_SUFFIX)";
        }

        public static bool is_block_placeholder (string text) {
            return text.has_prefix (BLOCK_PLACEHOLDER_PREFIX) && text.has_suffix (PLACEHOLDER_SUFFIX);
        }

        public static bool is_inline_placeholder (string text) {
            return text.has_prefix (INLINE_PLACEHOLDER_PREFIX) && text.has_suffix (PLACEHOLDER_SUFFIX);
        }

        public static int parse_placeholder_id (string placeholder) {
            int start = placeholder.last_index_of (":");
            if (start < 0) {
                return -1;
            }

            var id_text = placeholder.substring (start + 1);
            id_text = id_text.substring (0, id_text.length - PLACEHOLDER_SUFFIX.length);
            return int.parse (id_text);
        }
    }
}