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

  public delegate void ImportCallback( Note? first_note );

  //-------------------------------------------------------------
  // Exports the given note using the specified export type.
  public static void import_notes( MainWindow win, Notebook notebook, ImportCallback? callback ) {
    import_dialog( win, notebook, callback );
  }

  //-------------------------------------------------------------
  // Displays a dialog to the user prompting to specify an output name.
  private static void import_dialog( MainWindow win, Notebook notebook, ImportCallback? callback ) {

    Note? first_note = null;

    var filter = new FileFilter() {
      name = _( "Markdown" )
    };
    filter.add_suffix( "md" );

#if GTK410
    var dialog = Utils.make_file_chooser( _( "Import" ), _( "Import" ) );

    dialog.default_filter = filter;

    dialog.open_multiple.begin( win, null, (obj, res) => {
      try {
        var files = dialog.open_multiple.end( res );
        if( files != null ) {
          for( int i=0; i<files.get_n_items(); i++ ) {
            var file = (File)files.get_item( i );
            var note = do_import( notebook, file.get_path() );
            if( i == 0 ) {
              first_note = note;
            }
          }
          if( callback != null ) {
            callback( first_note );
          }
        }
      } catch( Error e ) {}
    });
#else
    var dialog = Utils.make_file_chooser( _( "Import" ), win, FileChooserAction.OPEN, _( "Import" ) );

    dialog.filter = filter;
    dialog.select_multiple = true;

    dialog.response.connect((id) => {
      if( id == ResponseType.ACCEPT ) {
        var files = dialog.get_files();
        if( files != null ) {
          for( int i=0; i<files.get_n_items(); i++ ) {
            var file = (File)files.get_item( i );
            var note = do_import( notebook, file.get_path() );
            if( i == 0 ) {
              first_note = note;
            }
          }
          if( callback != null ) {
            callback( first_note );
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
  private static Note? do_import( Notebook notebook, string filename ) {

    string contents = "";

    try {
      if( FileUtils.get_contents( filename, out contents ) ) {
        var parser = new NoteParser();
        var note   = parser.parse_markdown( notebook, contents );
        if( note != null ) {
          notebook.add_note( note );
        }
        return( note );
      }
    } catch( FileError e ) {}

    return( null );

  }

}