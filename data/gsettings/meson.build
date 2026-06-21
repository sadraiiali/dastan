schema = 'io.github.markviewer.gschema.xml'

schema_file = configure_file(
  input: schema,
  output: schema,
  copy: true,
  install: true,
  install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas'),
)

gnome.compile_schemas(
  build_by_default: true,
  depend_files: schema_file,
)