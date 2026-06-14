[CCode (cheader_filename = "cmark-gfm-extension_api.h", cprefix = "cmark_")]
namespace Cmark {
    [CCode (cheader_filename = "cmark-gfm.h", cprefix = "CMARK_", has_type_id = false)]
    public enum ListType {
        NO_LIST,
        BULLET_LIST,
        ORDERED_LIST,
    }

    [CCode (cheader_filename = "cmark-gfm.h", cname = "cmark_node", ref_function = "", unref_function = "")]
    public class Node {
    }

    [CCode (cheader_filename = "cmark-gfm.h", cname = "cmark_parser", ref_function = "", unref_function = "")]
    public class Parser {
    }

    [CCode (cheader_filename = "cmark-gfm.h", cname = "cmark_syntax_extension", ref_function = "", unref_function = "")]
    public class SyntaxExtension {
    }

    [CCode (cname = "cmark_gfm_core_extensions_ensure_registered", cheader_filename = "cmark-gfm-core-extensions.h")]
    public extern void gfm_core_extensions_ensure_registered ();

    public extern Parser parser_new (int options);
    public extern void parser_free (Parser parser);
    public extern void parser_feed (Parser parser, string buffer, size_t len);
    public extern Node? parser_finish (Parser parser);
    public extern int parser_attach_syntax_extension (Parser parser, SyntaxExtension extension);

    [CCode (cname = "cmark_find_syntax_extension")]
    public extern SyntaxExtension? find_syntax_extension (string name);

    public extern void node_free (Node node);
    public extern unowned Node? node_next (Node node);
    public extern unowned Node? node_first_child (Node node);
    public extern int node_get_type (Node node);
    public extern unowned string node_get_type_string (Node node);
    public extern unowned string? node_get_literal (Node node);
    public extern int node_get_heading_level (Node node);
    public extern ListType node_get_list_type (Node node);
    public extern int node_get_list_start (Node node);
    public extern unowned string? node_get_url (Node node);
    public extern unowned string? node_get_title (Node node);
    public extern unowned string? node_get_fence_info (Node node);

    [CCode (cname = "cmark_gfm_extensions_get_tasklist_item_checked", cheader_filename = "cmark-gfm-core-extensions.h")]
    public extern bool extensions_get_tasklist_item_checked (Node node);
}