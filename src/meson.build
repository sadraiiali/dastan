config_vala = configure_file(
  input: 'config.vala.in',
  output: 'config.vala',
  configuration: conf,
)

math_bridge = static_library(
  'math-bridge',
  'markdown/math/lasem_bridge.c',
  dependencies: [lasem_dep, cairo_dep],
  include_directories: include_directories('markdown/math'),
)

math_bridge_dep = declare_dependency(
  link_with: math_bridge,
  include_directories: include_directories('markdown/math'),
  dependencies: [lasem_dep, cairo_dep],
)

markdown_lib = static_library(
  'markdown-lib',
  'markdown/math/registry.vala',
  'markdown/math/renderer.vala',
  'markdown/math/widget.vala',
  'markdown/math/paragraph.vala',
  'markdown/preprocessor.vala',
  dependencies: [gtk_dep, cairo_dep, math_bridge_dep, glib_dep, gobject_dep],
  vala_args: vala_args,
  install: false,
)

markdown_lib_inc = include_directories('.')

markdown_lib_dep = declare_dependency(
  link_with: markdown_lib,
  include_directories: markdown_lib_inc,
  dependencies: [gtk_dep, cairo_dep, math_bridge_dep, glib_dep, gobject_dep],
)

app_sources = files(
  'main.vala',
  'font_config.vala',
  'application.vala',
  'ui/window.vala',
  'ui/theme.vala',
  'markdown/renderer.vala',
)

executable(
  'dastan',
  app_sources,
  config_vala,
  dependencies: [
    gtk_dep,
    adw_dep,
    gio_dep,
    cairo_dep,
    cmark_gfm_dep,
    math_bridge_dep,
    markdown_lib_dep,
  ],
  vala_args: vala_args,
  install: true,
)

executable(
  'dump-tree',
  'tools/tree_dumper.vala',
  dependencies: [glib_dep, gobject_dep, gio_dep, cmark_gfm_dep, markdown_lib_dep],
  vala_args: vala_args,
  install: false,
)

test_math_dep = markdown_lib_dep

if not meson.is_subproject()
  subdir('tests')
endif