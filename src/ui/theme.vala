namespace MarkViewer {
    public class MarkdownTheme {
        public struct Palette {
            public string fg;
            public string fg_muted;
            public string fg_accent;
            public string bg;
            public string bg_muted;
            public string bg_neutral;
            public string border;
            public string border_muted;
        }

        public static Palette palette (string theme_id) {
            switch (theme_id) {
                case "light":
                case "light-colorblind":
                    return {
                        "#1f2328", "#59636e", "#0969da",
                        "#ffffff", "#f6f8fa", "#818b981f",
                        "#d1d9e0", "#d1d9e0b3"
                    };
                case "dark-dimmed":
                    return {
                        "#f0f6fc", "#9198a1", "#478be6",
                        "#212830", "#262c36", "#656c7633",
                        "#3d444d", "#3d444db3"
                    };
                case "dark-high-contrast":
                    return {
                        "#ffffff", "#f0f6fc", "#71b7ff",
                        "#010409", "#151b23", "#212830",
                        "#b7bdc8", "#b7bdc8"
                    };
                case "dark":
                case "dark-colorblind":
                default:
                    return {
                        "#f0f6fc", "#9198a1", "#4493f8",
                        "#0d1117", "#151b23", "#656c7633",
                        "#3d444d", "#3d444db3"
                    };
            }
        }

        public static Palette light_palette () {
            return palette ("light");
        }

        public static Palette dark_palette () {
            return palette ("dark");
        }

        public static string css_for (string theme_id) {
            if (theme_id == "auto") {
                return css_for_palette ("auto", light_palette (), true, false)
                     + css_for_palette ("auto", dark_palette (), false, true);
            }

            return css_for_palette (theme_id, palette (theme_id), false, false);
        }

        private static string css_for_palette (
            string theme_class,
            Palette p,
            bool light_media,
            bool dark_media
        ) {
            var selector_prefix = "";
            var selector_suffix = "";

            if (light_media) {
                selector_prefix = "@media (prefers-color-scheme: light) {\n";
                selector_suffix = "\n}";
            } else if (dark_media) {
                selector_prefix = "@media (prefers-color-scheme: dark) {\n";
                selector_suffix = "\n}";
            }

            return selector_prefix
                 + palette_rules (@"window.md-theme-$theme_class", p)
                 + palette_rules (@"dialog.md-theme-$theme_class", p)
                 + settings_dialog_surface_rules (@"dialog.md-theme-$theme_class", p)
                 + selector_suffix;
        }

        private static string settings_dialog_surface_rules (string root, Palette p) {
            return """
                %s.md-settings-dialog {
                  --fgColor-default: %s;
                  --fgColor-muted: %s;
                  --fgColor-accent: %s;
                  --bgColor-default: %s;
                  --bgColor-muted: %s;
                  --window-bg-color: %s;
                  --window-fg-color: %s;
                  --view-bg-color: %s;
                  --view-fg-color: %s;
                  --card-bg-color: %s;
                  --card-fg-color: %s;
                  --card-shade-color: %s;
                  --border-color: %s;
                  --accent-bg-color: %s;
                  --accent-fg-color: %s;
                  --accent-color: %s;
                  --dim-opacity: 1;
                  background-color: %s;
                  color: %s;
                }
                %s.md-settings-dialog floating-sheet .background,
                %s.md-settings-dialog bottom-sheet .background,
                %s.md-settings-dialog toolbarview,
                %s.md-settings-dialog headerbar,
                %s.md-settings-dialog scrolledwindow,
                %s.md-settings-dialog .md-settings-content {
                  background-color: %s;
                  color: %s;
                }
                %s.md-settings-dialog listbox.md-settings-list {
                  background-color: transparent;
                  color: %s;
                  border: none;
                  box-shadow: none;
                }
                %s.md-settings-dialog listbox.md-settings-list > row {
                  background-color: %s;
                  color: %s;
                  border: 1px solid %s;
                  border-radius: 8px;
                }
                %s.md-settings-dialog listbox.md-settings-list row label.title {
                  color: %s;
                  opacity: 1;
                }
                %s.md-settings-dialog listbox.md-settings-list row label.subtitle {
                  color: %s;
                  opacity: 1;
                }
                %s.md-settings-dialog dropdown,
                %s.md-settings-dialog dropdown button,
                %s.md-settings-dialog dropdown label,
                %s.md-settings-dialog .md-settings-theme-dropdown,
                %s.md-settings-dialog .md-settings-theme-dropdown button,
                %s.md-settings-dialog .md-settings-theme-dropdown label {
                  color: %s;
                  background-color: transparent;
                  opacity: 1;
                }
                %s.md-settings-dialog dropdown image {
                  color: %s;
                  opacity: 1;
                }
                %s.md-settings-dialog row switch {
                  color: %s;
                }
                %s.md-settings-dialog popover,
                %s.md-settings-dialog popover contents,
                %s.md-settings-dialog popover scrolledwindow,
                %s.md-settings-dialog popover listview,
                %s.md-settings-dialog popover listview row {
                  background-color: %s;
                  color: %s;
                }
                %s.md-settings-dialog popover listview label {
                  color: %s;
                  opacity: 1;
                }
                %s.md-settings-dialog popover listview row:selected,
                %s.md-settings-dialog popover listview row:selected label {
                  background-color: %s;
                  color: %s;
                }
                """.printf (
                root, p.fg, p.fg_muted, p.fg_accent, p.bg, p.bg_muted,
                p.bg, p.fg, p.bg_muted, p.fg, p.bg_muted, p.fg, p.border_muted, p.border,
                p.fg_accent, p.fg, p.fg_accent, p.bg, p.fg,
                root, root, root, root, root, root, p.bg, p.fg,
                root, p.fg,
                root, p.bg_muted, p.fg, p.border,
                root, p.fg,
                root, p.fg_muted,
                root, root, root, root, root, root, p.fg_accent,
                root, p.fg_muted,
                root, p.fg_accent,
                root, root, root, root, root, p.bg, p.fg,
                root, p.fg,
                root, root, p.bg_muted, p.fg
            );
        }

        private static string palette_rules (string root, Palette p) {
            return """
                %s {
                  --fgColor-default: %s;
                  --fgColor-muted: %s;
                  --fgColor-accent: %s;
                  --bgColor-default: %s;
                  --bgColor-muted: %s;
                  --bgColor-neutral-muted: %s;
                  --borderColor-default: %s;
                  --borderColor-muted: %s;
                  background-color: %s;
                  color: %s;
                }
                %s toolbarview,
                %s headerbar,
                %s scrolledwindow {
                  background-color: %s;
                  color: %s;
                }
                %s headerbar button,
                %s headerbar .title {
                  color: %s;
                }
                %s floating-sheet .background,
                %s bottom-sheet .background,
                %s .md-settings-content,
                %s preferencesgroup,
                %s actionrow,
                %s comborow,
                %s listboxrow,
                %s popover,
                %s popover contents,
                %s listbox {
                  background-color: %s;
                  color: %s;
                }
                %s label,
                %s button,
                %s .title-2,
                %s .title-3,
                %s .title-4,
                %s .heading {
                  color: %s;
                }
                %s .dim-label,
                %s actionrow .subtitle,
                %s comborow .subtitle {
                  color: %s;
                }
                %s button {
                  background-color: %s;
                  border-color: %s;
                }
                %s separator {
                  background-color: %s;
                }
                %s .markdown-body,
                %s .markdown-body label,
                %s .md-h1,
                %s .md-h2,
                %s .md-h3,
                %s .md-h4,
                %s .md-h5,
                %s .md-paragraph,
                %s .md-list-paragraph,
                %s .md-code-block,
                %s .md-math-source {
                  color: %s;
                }
                %s .md-h6,
                %s .md-empty,
                %s .md-blockquote,
                %s .md-blockquote label,
                %s .md-blockquote .md-paragraph,
                %s .md-list-marker,
                %s .md-image-alt {
                  color: %s;
                }
                %s .md-table-cell,
                %s .md-table-cell label,
                %s .markdown-body tt {
                  color: %s;
                }
                %s .markdown-body label link {
                  color: %s;
                }
                """.printf (
                root, p.fg, p.fg_muted, p.fg_accent, p.bg, p.bg_muted, p.bg_neutral, p.border, p.border_muted, p.bg, p.fg,
                root, root, root, p.bg, p.fg,
                root, root, p.fg,
                root, root, root, root, root, root, root, root, root, root, p.bg, p.fg,
                root, root, root, root, root, root, p.fg,
                root, root, root, p.fg_muted,
                root, p.bg_muted, p.border,
                root, p.border,
                root, root, root, root, root, root, root, root, root, root, root, p.fg,
                root, root, root, root, root, root, root, p.fg_muted,
                root, root, root, p.fg,
                root, p.fg_accent
            );
        }
    }
}