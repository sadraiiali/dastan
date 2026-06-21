viewer_opt = get_option('viewer')
if viewer_opt.disabled()
  viewer_value = 'disabled'
elif viewer_opt.enabled()
  viewer_value = 'enabled'
else
  viewer_value = 'auto'
endif

lasem_sub = subproject(
  'lasem',
  default_options: [
    'default_library=static',
    'introspection=disabled',
    'viewer=' + viewer_value,
    'documentation=disabled',
    'c_args=-D_GNU_SOURCE',
  ],
)

lasem_dep = lasem_sub.get_variable('lasem_library_dependencies')