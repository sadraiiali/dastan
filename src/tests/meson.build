fonts_conf = join_paths(meson.project_build_root(), 'data', 'dastan-fonts.conf')
math_test_env = [
  'GDK_BACKEND=x11',
  'FONTCONFIG_FILE=' + fonts_conf,
]

test_registry = executable(
  'test-math-registry',
  'unit/test_math_registry.vala',
  dependencies: [glib_dep, gobject_dep, test_math_dep],
  vala_args: vala_args,
  install: false,
)

test_preprocessor = executable(
  'test-preprocessor',
  'unit/test_preprocessor.vala',
  dependencies: [glib_dep, gobject_dep, test_math_dep],
  vala_args: vala_args,
  install: false,
)

test_math_renderer = executable(
  'test-math-renderer',
  'unit/test_math_renderer.vala',
  dependencies: [gtk_dep, cairo_dep, math_bridge_dep, test_math_dep],
  vala_args: vala_args,
  install: false,
)

test_math_widget = executable(
  'test-math-widget',
  'unit/test_math_widget.vala',
  dependencies: [gtk_dep, cairo_dep, math_bridge_dep, test_math_dep],
  vala_args: vala_args,
  install: false,
)

test(
  'math-registry',
  test_registry,
  protocol: 'tap',
)

test(
  'preprocessor',
  test_preprocessor,
  protocol: 'tap',
)

test(
  'math-renderer',
  test_math_renderer,
  protocol: 'tap',
  env: math_test_env,
)

test(
  'math-widget',
  test_math_widget,
  protocol: 'tap',
  env: math_test_env,
)