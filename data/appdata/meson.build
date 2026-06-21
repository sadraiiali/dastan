metainfo_config = configuration_data()
metainfo_config.set('app_id', app_id)
metainfo_file_in = configure_file(
  input: 'io.github.markviewer.metainfo.xml.in.in',
  output: 'io.github.markviewer.metainfo.xml.in',
  configuration: metainfo_config,
)
metainfo_file = i18n.merge_file(
  input: metainfo_file_in,
  output: '@0@.metainfo.xml'.format(app_id),
  po_dir: '../../po',
  install: true,
  install_dir: join_paths(get_option('datadir'), 'metainfo'),
)

appstreamcli = find_program('appstreamcli', required: false)
if appstreamcli.found()
  test('Validate appstream file', appstreamcli, args: ['validate', '--no-net', metainfo_file])
endif