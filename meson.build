project(
  'dastan',
  ['vala', 'c'],
  version: '0.2.0',
  license: 'AGPL-3.0-or-later',
  meson_version: '>= 0.59',
  default_options: ['buildtype=debugoptimized', 'c_std=c11'],
)

app_id = 'io.github.markviewer'

add_project_arguments(
  '-Wno-unused-but-set-variable',
  '-Wno-unused-variable',
  '-Wno-unused-label',
  '-Wno-discarded-qualifiers',
  language: 'c',
)

gtk_dep = dependency('gtk4', version: '>= 4.12')
adw_dep = dependency('libadwaita-1', version: '>= 1.5')
gio_dep = dependency('gio-2.0', version: '>= 2.74')
cairo_dep = dependency('cairo')
glib_dep = dependency('glib-2.0')
gobject_dep = dependency('gobject-2.0')

gnome = import('gnome')
i18n = import('i18n')

subdir('external/cmark-gfm-meson')
subdir('external/lasem-meson')

dev_data_dir = join_paths(meson.current_source_dir(), 'data')
install_data_dir = join_paths(get_option('prefix'), get_option('datadir'), 'dastan')

conf = configuration_data()
conf.set('DEV_DATA_DIR', dev_data_dir)
conf.set('INSTALLED_DATA_DIR', install_data_dir)
conf.set('DEV_FONTS_CONF', join_paths(meson.current_build_dir(), 'data', 'dastan-fonts.conf'))
conf.set('INSTALLED_FONTS_CONF', join_paths(install_data_dir, 'dastan-fonts.conf'))
conf.set('DEV_SCHEMAS_DIR', join_paths(meson.current_build_dir(), 'data', 'gsettings'))
conf.set(
  'INSTALLED_SCHEMAS_DIR',
  join_paths(get_option('prefix'), get_option('datadir'), 'glib-2.0', 'schemas'),
)

vala_args = [
  '--vapidir', meson.current_source_dir() / 'src' / 'vapi',
  '--pkg', 'cmark-gfm',
  '--pkg', 'markviewer-math',
]

subdir('data')
subdir('src')
subdir('po')

gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true,
)

meson.add_install_script('build-aux/meson/post_install.py')