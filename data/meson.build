subdir('appdata')
subdir('fonts')
subdir('gsettings')
subdir('icons')

install_data(
  'markviewer.css',
  'markdown-themes.css',
  install_dir: install_data_dir,
)

fonts_conf_dev = configuration_data()
fonts_conf_dev.set('FONTS_DIR', join_paths(dev_data_dir, 'fonts'))

configure_file(
  input: 'fonts/dastan-fonts.conf.in',
  output: 'dastan-fonts.conf',
  configuration: fonts_conf_dev,
)

fonts_conf_install = configuration_data()
fonts_conf_install.set('FONTS_DIR', join_paths(install_data_dir, 'fonts'))

installed_fonts_conf = configure_file(
  input: 'fonts/dastan-fonts.conf.in',
  output: 'dastan-fonts-installed.conf',
  configuration: fonts_conf_install,
)

install_data(
  installed_fonts_conf,
  install_dir: install_data_dir,
  rename: 'dastan-fonts.conf',
)

desktop_file_config = configuration_data()
desktop_file_config.set('app_id', app_id)
desktop_file_in = configure_file(
  input: 'io.github.markviewer.desktop.in.in',
  output: 'io.github.markviewer.desktop.in',
  configuration: desktop_file_config,
)
desktop_file = i18n.merge_file(
  input: desktop_file_in,
  output: '@0@.desktop'.format(app_id),
  type: 'desktop',
  po_dir: '../po',
  install: true,
  install_dir: join_paths(get_option('datadir'), 'applications'),
)

desktop_utils = find_program('desktop-file-validate', required: false)
if desktop_utils.found()
  test('Validate desktop file', desktop_utils, args: [desktop_file])
endif

