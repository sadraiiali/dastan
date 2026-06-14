project(
  'dastan',
  ['vala', 'c'],
  version: '0.2.0',
  license: 'AGPL-3.0-or-later',
  meson_version: '>= 0.59',
  default_options: ['buildtype=debugoptimized', 'c_std=c11'],
)

gtk_dep = dependency('gtk4', version: '>= 4.12')
adw_dep = dependency('libadwaita-1', version: '>= 1.5')

subdir('external/cmark-gfm-meson')

dev_data_dir = join_paths(meson.current_source_dir(), 'assets')
install_data_dir = join_paths(get_option('prefix'), get_option('datadir'), 'dastan')

fonts_conf_dev = configuration_data()
fonts_conf_dev.set('FONTS_DIR', join_paths(dev_data_dir, 'fonts'))

configure_file(
  input: 'assets/dastan-fonts.conf.in',
  output: 'dastan-fonts.conf',
  configuration: fonts_conf_dev,
)

fonts_conf_install = configuration_data()
fonts_conf_install.set('FONTS_DIR', join_paths(install_data_dir, 'fonts'))

installed_fonts_conf = configure_file(
  input: 'assets/dastan-fonts.conf.in',
  output: 'dastan-fonts-installed.conf',
  configuration: fonts_conf_install,
)

install_data(
  installed_fonts_conf,
  install_dir: install_data_dir,
  rename: 'dastan-fonts.conf',
)

install_data('assets/markviewer.css', install_dir: install_data_dir)
install_subdir('assets/fonts', install_dir: install_data_dir)

conf = configuration_data()
conf.set('DEV_DATA_DIR', dev_data_dir)
conf.set('INSTALLED_DATA_DIR', install_data_dir)
conf.set('DEV_FONTS_CONF', join_paths(meson.current_build_dir(), 'dastan-fonts.conf'))
conf.set('INSTALLED_FONTS_CONF', join_paths(install_data_dir, 'dastan-fonts.conf'))

config_vala = configure_file(
  input: 'src/config.vala.in',
  output: 'config.vala',
  configuration: conf,
)

sources = files(
  'src/main.vala',
  'src/font_config.vala',
  'src/application.vala',
  'src/window.vala',
  'src/math_registry.vala',
  'src/math_widget.vala',
  'src/markdown_preprocessor.vala',
  'src/markdown_renderer.vala',
)

vala_args = [
  '--vapidir', meson.current_source_dir() / 'src' / 'vapi',
  '--pkg', 'cmark-gfm',
]

executable(
  'dastan',
  sources,
  config_vala,
  dependencies: [gtk_dep, adw_dep, cmark_gfm_dep],
  vala_args: vala_args,
  install: true,
)

glib_dep = dependency('glib-2.0')
gobject_dep = dependency('gobject-2.0')
gio_dep = dependency('gio-2.0')

executable(
  'dump-tree',
  files(
    'src/tree_dumper.vala',
    'src/math_registry.vala',
    'src/markdown_preprocessor.vala',
  ),
  dependencies: [glib_dep, gobject_dep, gio_dep, cmark_gfm_dep],
  vala_args: vala_args,
  install: false,
)