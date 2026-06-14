src_inc = include_directories('src', 'build-support', 'build-support')
ext_inc = include_directories('extensions', 'src', 'build-support')

src_sources = files(
  'src/arena.c',
  'src/blocks.c',
  'src/buffer.c',
  'src/cmark.c',
  'src/cmark_ctype.c',
  'src/commonmark.c',
  'src/footnotes.c',
  'src/houdini_href_e.c',
  'src/houdini_html_e.c',
  'src/houdini_html_u.c',
  'src/html.c',
  'src/inlines.c',
  'src/iterator.c',
  'src/latex.c',
  'src/linked_list.c',
  'src/man.c',
  'src/map.c',
  'src/node.c',
  'src/plaintext.c',
  'src/plugin.c',
  'src/references.c',
  'src/registry.c',
  'src/render.c',
  'src/scanners.c',
  'src/syntax_extension.c',
  'src/utf8.c',
  'src/xml.c',
)

ext_sources = files(
  'extensions/autolink.c',
  'extensions/core-extensions.c',
  'extensions/ext_scanners.c',
  'extensions/strikethrough.c',
  'extensions/table.c',
  'extensions/tagfilter.c',
  'extensions/tasklist.c',
)

cmark_gfm_lib = static_library(
  'cmark-gfm',
  src_sources + ext_sources,
  include_directories: [src_inc, ext_inc],
  c_args: [
    '-DCMARK_GFM_STATIC_DEFINE',
    '-DCMARK_GFM_EXTENSIONS_STATIC_DEFINE',
  ],
)

cmark_gfm_dep = declare_dependency(
  link_with: cmark_gfm_lib,
  include_directories: [src_inc, ext_inc],
)