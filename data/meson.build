icon_sizes = ['16','24','32', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        join_paths('icons', i, meson.project_name() + '.png'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
    )
endforeach

i18n.merge_file(
    input: meson.project_name() + '.desktop.in',
    output: meson.project_name() + '.desktop',
    po_dir: join_paths(meson.project_source_root(), 'po', 'extra'),
    type: 'desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications')
)

i18n.merge_file(
    input: meson.project_name() + '.appdata.xml.in',
    output: meson.project_name() + '.appdata.xml',
    po_dir: join_paths(meson.project_source_root(), 'po', 'extra'),
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)

install_data(
    meson.project_name() + '.gschema.xml',
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

install_data(
    meson.project_name() + '.mime.xml',
    install_dir: join_paths(get_option('datadir'), 'mime', 'packages')
)

langs = ['plantuml', 'mosaic-markdown']

foreach lang : langs
    install_data(
        join_paths('syntax', lang + '.lang'),
        install_dir: join_paths(get_option('datadir'), 'mosaic-note', 'gtksourceview-5', 'language-specs')
    )
endforeach

install_subdir(
    'pandoc-langs',
    install_dir: join_paths(get_option('datadir'), 'mosaic-note')
)
