/*
* Copyright (c) 2024-2026 (https://github.com/phase1geo/MosaicNote)
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

  public delegate void ImportNoteCallback( Notebook notebook, Note? note, bool last );
  public delegate void ImportFolderCallback();

  //-------------------------------------------------------------
  // Imports one or more notes selected from a dialog.
  public static void import_notes( MainWindow win, Notebook notebook, ImportNoteCallback? callback ) {
    import_note_dialog( win, notebook, callback );
  }

  //-------------------------------------------------------------
  // Imports notebooks and notes from a folder from the file
  // system.
  public static void import_folder( MainWindow win, NotebookTree.Node? node, ImportFolderCallback? callback ) {
    import_folder_dialog( win, node, callback );
  }

  //-------------------------------------------------------------
  // Displays a dialog to the user prompting to specify an output name.
  private static void import_note_dialog( MainWindow win, Notebook notebook, ImportNoteCallback? callback ) {

    var md_filter = new FileFilter() {
      name = _( "Markdown" )
    };
    md_filter.add_suffix( "md" );
    md_filter.add_suffix( "markdown" );

    var dialog = Utils.make_file_chooser( _( "Import Notes" ), _( "Import" ) );

    dialog.default_filter = md_filter;

    dialog.open_multiple.begin( win, null, (obj, res) => {
      try {
        var files = dialog.open_multiple.end( res );
        if( files != null ) {
          var last_index = files.get_n_items() - 1;
          for( int i=0; i<files.get_n_items(); i++ ) {
            var file = (File)files.get_item( i );
            do_note_import( notebook, file.get_path(), callback, (i == last_index) );
          }
        }
      } catch( Error e ) {}
    });

  }

  //-------------------------------------------------------------
  // Displays a folder dialog to import notebooks and notes.
  private static void import_folder_dialog( MainWindow win, NotebookTree.Node? node, ImportFolderCallback? callback ) {

    var dialog = Utils.make_file_chooser( _( "Import Folder" ), _( "Import" ) );

    dialog.select_folder.begin( win, null, (obj, res) => {
      try {
        var folder = dialog.select_folder.end( res );
        if( folder != null ) {
          do_folder_import( win, folder, node, callback );
        }
      } catch( Error e ) {}
    });

  }

  //-------------------------------------------------------------
  // Imports all notebooks and notes from a given folder.
  private static void do_folder_import( MainWindow win, File folder, NotebookTree.Node node, ImportFolderCallback? callback ) {

    var notebook = new Notebook( folder.get_basename() );

    NotebookTree.Node new_node;
    if( node != null ) {
      new_node = node.add_notebook( notebook );
    } else {
      new_node = win.notebooks.add_notebook( notebook );
    }

    var enumerator = folder.enumerate_children( "standard::*", FileQueryInfoFlags.NOFOLLOW_SYMLINKS, null );

    FileInfo info = null;
    while( (info = enumerator.next_file(null)) != null ) {
      var item = folder.resolve_relative_path( info.get_name() );
      if( info.get_file_type () == FileType.DIRECTORY ) {
        do_folder_import( win, item, new_node, callback );
      } else if( info.get_name().has_suffix( ".md" ) || 
                 info.get_name().has_suffix( ".markdown" ) ) {
        var contents = "";
        try {
          if( FileUtils.get_contents( item.get_path(), out contents ) ) {
            var parser = new NoteParser();
            var note   = parser.parse_markdown( notebook, contents );
            notebook.add_note( note );
          }
        } catch( FileError e ) {}
      }
    }

    if( notebook.count() > 0 ) {
      if( callback != null ) {
        callback();
      }
    }

  }

  //-------------------------------------------------------------
  // Performs the export operation.  Returns the note that was imported.
  private static void do_note_import( Notebook notebook, string filename, ImportNoteCallback callback, bool last ) {

    string contents = "";

    try {
      if( FileUtils.get_contents( filename, out contents ) ) {
        var parser = new NoteParser();
        var note   = parser.parse_markdown( notebook, contents );
        callback( notebook, note, last );
      }
    } catch( FileError e ) {}

  }

  //-------------------------------------------------------------
  // Creates a new note from the given filename.  We will figure out
  // what the filename type is and create the note to best match.
  // 
  // Image file:     Create a note with an image block
  // Markdown file:  Create a note from the Markdown
  // Text file:      Create a note with text in a single Markdown block
  // Binary file:    Create a note with an assets block.
  public static void do_file_import( Notebook notebook, File file, ImportNoteCallback? callback = null ) {

    // If we have a Markdown file, parse it and add it as a fully featured note.
    if( file.get_path() != null ) {
      var ext = Utils.get_extension( file.get_path() );
      if( (ext == "md") || (ext == "markdown") ) {
        do_note_import( notebook, file.get_path(), callback, true );
        return;
      }
    }

    // Create the note and a note row
    var note = new Note( notebook, false );
    var row  = new NoteItemRow( note );
    note.add_row( row );

    // If the file is a supported image, add an image block to the note.
    if( Utils.is_uri_supported_image( file.get_uri() ) ) {
      var item = new NoteItemImage( row ) {
        uri = file.get_uri()
      };
      row.add_item( item );

    // Otherwise, add the file as a single Markdown block (if it is a code segment, it can be easily changed)
    } else {
      try {
        string contents = "";
        if( FileUtils.get_contents( file.get_path(), out contents ) ) {
          if( contents.validate( 2 ) ) {
            var item = new NoteItemMarkdown( row ) {
              content = contents
            };
            row.add_item( item );
          } else {
            var item = new NoteItemAssets( row );
            item.add_asset( file.get_uri() );
            row.add_item( item );
          }
        } else {
          return;
        }
      } catch( FileError e ) {
        return;
      }
    }

    // Finally, perform the callback
    if( callback != null ) {
      callback( notebook, note, true );
    }

  }

  //-------------------------------------------------------------
  // Creates a new note from the given text string.
  public static void do_text_import( Notebook notebook, string text, ImportNoteCallback? callback = null ) {

    var url = Utils.is_url( text );

    if( (FileUtils.test( text.chomp(), FileTest.EXISTS ) && text.has_prefix( "/" )) || url ) {
      if( text.has_prefix( "file://" ) || url ) {
        var file = File.new_for_uri( text );
        do_file_import( notebook, file, callback );
      } else {
        var file = File.new_for_path( text );
        do_file_import( notebook, file, callback );
      }
      return;
    }

    var parser = new NoteParser();
    var note   = parser.parse_markdown( notebook, text );

    if( callback != null ) {
      callback( notebook, note, true );
    }

  }

}
