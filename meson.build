project('com.github.phase1geo.mosaic-note', ['vala', 'c'],
  meson_version : '>= 0.59.0',
  version : '1.0.0',
  license: 'GPL-3.0'
)

i18n  = import('i18n')
gnome = import('gnome')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

config_data = configuration_data()
config_data.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

gresource = gnome.compile_resources(
    'mosaic-note-resources', 'data/' + meson.project_name() + '.gresource.xml',
    build_by_default: true,
    source_dir: 'data',
)

sources = files()

subdir('data')
subdir('po')
subdir('src')

# Work around deprecated code to avoid warnings
gtk4_dep = dependency('gtk4')
if gtk4_dep.version().version_compare('>=4.10.0')
  add_project_arguments(['--define=GTK410'], language: 'vala')
endif
if gtk4_dep.version().version_compare('>=4.12.0')
  add_project_arguments(['--define=GTK412'], language: 'vala')
endif

core_deps = [
    dependency('gobject-2.0'),
    dependency('glib-2.0'),
    meson.get_compiler('vala').find_library('posix'),
    meson.get_compiler('c').find_library('m', required : false),
    # meson.get_compiler('c').find_library('markdown', required : true),
    # meson.get_compiler('c').find_library('yaml', required : true),
    dependency('gee-0.8'),
    dependency('granite-7'),
    dependency('gtk4'),
    dependency('libxml-2.0'),
    dependency('gtksourceview-5'),
    dependency('json-glib-1.0'),
    dependency('enchant-2'),
    dependency('webkitgtk-6.0')
]

e = executable('com.github.phase1geo.mosaic-note',
    sources,
    config_file,
    gresource,
    dependencies: core_deps,
    # vala_args: [
    #     meson.project_source_root() + '/vapi/libmarkdown.vapi',
    #     meson.project_source_root() + '/vapi/yaml-0.1.vapi'
    # ],
    install : true
)

gnome.post_install(
    glib_compile_schemas: true,
    gtk_update_icon_cache: true,
    update_desktop_database: true,
)

# If our version of Meson supports it, update the mime database
if meson.version().version_compare('>=0.64.0')
  gnome.post_install(
    update_mime_database: true,
  )
endif
