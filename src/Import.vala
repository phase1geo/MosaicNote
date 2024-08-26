/*
* Copyright (c) 2024 (https://github.com/phase1geo/MosaicNote)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Trevor Williams <phase1geo@gmail.com>
*/

using Gtk;

public class Import {

  public delegate void ImportCallback( Note? note, bool last );

  //-------------------------------------------------------------
  // Exports the given note using the specified export type.
  public static void import_notes( MainWindow win, Notebook notebook, ImportCallback? callback ) {
    import_dialog( win, notebook, callback );
  }

  //-------------------------------------------------------------
  // Displays a dialog to the user prompting to specify an output name.
  private static void import_dialog( MainWindow win, Notebook notebook, ImportCallback? callback ) {

    var md_filter = new FileFilter() {
      name = _( "Markdown" )
    };
    md_filter.add_suffix( "md" );

#if GTK410
    var dialog = Utils.make_file_chooser( _( "Import" ), _( "Import" ) );

    dialog.default_filter = md_filter;

    dialog.open_multiple.begin( win, null, (obj, res) => {
      try {
        var files = dialog.open_multiple.end( res );
        if( files != null ) {
          var last_index = files.get_n_items() - 1;
          for( int i=0; i<files.get_n_items(); i++ ) {
            var file = (File)files.get_item( i );
            do_import( notebook, file.get_path(), callback, (i == last_index) );
          }
        }
      } catch( Error e ) {}
    });
#else
    var dialog = Utils.make_file_chooser( _( "Import" ), win, FileChooserAction.OPEN, _( "Import" ) );

    dialog.filter = md_filter;
    dialog.select_multiple = true;

    dialog.response.connect((id) => {
      if( id == ResponseType.ACCEPT ) {
        var files = dialog.get_files();
        if( files != null ) {
          var last_index = files.get_n_items() - 1;
          for( int i=0; i<files.get_n_items(); i++ ) {
            var file = (File)files.get_item( i );
            do_import( notebook, file.get_path(), callback, (i == last_index) );
          }
        }
      }
      dialog.destroy();
    });

    dialog.show();
#endif

  }

  //-------------------------------------------------------------
  // Performs the export operation.  Returns the note that was imported.
  private static void do_import( Notebook notebook, string filename, ImportCallback callback, bool last ) {

    string contents = "";

    try {
      if( FileUtils.get_contents( filename, out contents ) ) {
        var parser = new NoteParser();
        var note   = parser.parse_markdown( notebook, contents );
        callback( note, last );
      }
    } catch( FileError e ) {}

  }

}