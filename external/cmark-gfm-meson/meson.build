fs = import('fs')

cmark_root = meson.current_source_dir() / '..' / 'cmark-gfm'
build_support = meson.current_source_dir() / 'build-support'

assert(
  fs.exists(cmark_root / 'src' / 'cmark.c'),
  'cmark-gfm submodule missing — run: git submodule update --init',
)

cmark_inc_args = [
  '-I' + (cmark_root / 'src'),
  '-I' + (cmark_root / 'extensions'),
  '-I' + build_support,
]

overlay_inc = include_directories('build-support')

src_sources = files(
  cmark_root / 'src' / 'arena.c',
  cmark_root / 'src' / 'blocks.c',
  cmark_root / 'src' / 'buffer.c',
  cmark_root / 'src' / 'cmark.c',
  cmark_root / 'src' / 'cmark_ctype.c',
  cmark_root / 'src' / 'commonmark.c',
  cmark_root / 'src' / 'footnotes.c',
  cmark_root / 'src' / 'houdini_href_e.c',
  cmark_root / 'src' / 'houdini_html_e.c',
  cmark_root / 'src' / 'houdini_html_u.c',
  cmark_root / 'src' / 'html.c',
  cmark_root / 'src' / 'inlines.c',
  cmark_root / 'src' / 'iterator.c',
  cmark_root / 'src' / 'latex.c',
  cmark_root / 'src' / 'linked_list.c',
  cmark_root / 'src' / 'man.c',
  cmark_root / 'src' / 'map.c',
  cmark_root / 'src' / 'node.c',
  cmark_root / 'src' / 'plaintext.c',
  cmark_root / 'src' / 'plugin.c',
  cmark_root / 'src' / 'references.c',
  cmark_root / 'src' / 'registry.c',
  cmark_root / 'src' / 'render.c',
  cmark_root / 'src' / 'scanners.c',
  cmark_root / 'src' / 'syntax_extension.c',
  cmark_root / 'src' / 'utf8.c',
  cmark_root / 'src' / 'xml.c',
)

ext_sources = files(
  cmark_root / 'extensions' / 'autolink.c',
  cmark_root / 'extensions' / 'core-extensions.c',
  cmark_root / 'extensions' / 'ext_scanners.c',
  cmark_root / 'extensions' / 'strikethrough.c',
  cmark_root / 'extensions' / 'table.c',
  cmark_root / 'extensions' / 'tagfilter.c',
  cmark_root / 'extensions' / 'tasklist.c',
)

cmark_gfm_lib = static_library(
  'cmark-gfm',
  src_sources + ext_sources,
  include_directories: overlay_inc,
  c_args: cmark_inc_args + [
    '-DCMARK_GFM_STATIC_DEFINE',
    '-DCMARK_GFM_EXTENSIONS_STATIC_DEFINE',
  ],
)

cmark_gfm_dep = declare_dependency(
  link_with: cmark_gfm_lib,
  include_directories: overlay_inc,
  compile_args: cmark_inc_args,
)