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

public enum ExportType {
  MARKDOWN,
  TEXTBUNDLE,
  HTML,
  LATEX,
  EPUB,
  DOCX,
  PPTX,
  ODT,
  RTF,
  TEXT,
  NUM;

  public string to_string() {
    switch( this ) {
      case MARKDOWN   :  return( "markdown" );
      case TEXTBUNDLE :  return( "textbundle" );
      case HTML       :  return( "html" );
      case LATEX      :  return( "latex" );
      case EPUB       :  return( "epub" );
      case DOCX       :  return( "docx" );
      case PPTX       :  return( "pptx" );
      case ODT        :  return( "odt" );
      case RTF        :  return( "rtf" );
      case TEXT       :  return( "text" );
      default         :  assert_not_reached();
    }
  }

  public string label() {
    switch( this ) {
      case MARKDOWN   :  return( _( "Markdown" ) );
      case TEXTBUNDLE :  return( _( "TextBundle" ) );
      case HTML       :  return( _( "HTML" ) );
      case LATEX      :  return( _( "Latex" ) );
      case EPUB       :  return( _( "EPub" ) );
      case DOCX       :  return( _( "Microsoft Word" ) );
      case PPTX       :  return( _( "Microsoft PowerPoint" ) );
      case ODT        :  return( _( "ODT" ) );
      case RTF        :  return( _( "Rich Text Format" ) );
      case TEXT       :  return( _( "Plain Text" ) );
      default         :  assert_not_reached();
    }
  }

  public static ExportType parse( string val ) {
    switch( val ) {
      case "markdown"   :  return( MARKDOWN );
      case "textbundle" :  return( TEXTBUNDLE );
      case "html"       :  return( HTML );
      case "latex"      :  return( LATEX );
      case "epub"       :  return( EPUB );
      case "docx"       :  return( DOCX );
      case "pptx"       :  return( PPTX );
      case "odt"        :  return( ODT );
      case "rtf"        :  return( RTF );
      case "text"       :  return( TEXT );
      default           :  return( MARKDOWN );
    }
  }

  public string extension() {
    switch( this ) {
      case MARKDOWN   :  return( "md" );
      case TEXTBUNDLE :  return( "textbundle" );
      case HTML       :  return( "html" );
      case LATEX      :  return( "latex" );
      case EPUB       :  return( "epub" );
      case DOCX       :  return( "docx" );
      case PPTX       :  return( "pptx" );
      case ODT        :  return( "odt" );
      case RTF        :  return( "rtf" );
      case TEXT       :  return( "txt" );
      default         :  assert_not_reached();
    }
  }

}

public class Export {

  //-------------------------------------------------------------
  // Exports the given notebook to a user-selected directory.
  public static void export_notebook( MainWindow win, Notebook notebook ) {

#if GTK410
    var dialog = Utils.make_file_chooser( _( "Export" ), _( "Export" ) );

    dialog.select_folder.begin( win, null, (obj, res) => {
      try {
        var file = dialog.save.end( res );
        if( file != null ) {
          notebook.export( win.notebooks, file.get_path() );
        }
      } catch( Error e ) {}
    });
#else
    var dialog = Utils.make_file_chooser( _( "Export" ), win, FileChooserAction.SELECT_FOLDER, _( "Export" ) );

    dialog.response.connect((id) => {
      if( id == ResponseType.ACCEPT ) {
        var file = dialog.get_file();
        if( file != null ) {
          notebook.export( win.notebooks, file.get_path() );
        }
      }
      dialog.destroy();
    });

    dialog.show();
#endif
  }

  //-------------------------------------------------------------
  // Exports the given note using the specified export type.
  public static void export_note( MainWindow win, ExportType export_type, Note note, int item_index = -1 ) {
    export_dialog( win, export_type, note, null );
  }

  //-------------------------------------------------------------
  // Exports the given note item using the specified export type.
  public static void export_note_item( MainWindow win, ExportType export_type, NoteItem item ) {
    export_dialog( win, export_type, null, item );
  }

  //-------------------------------------------------------------
  // Displays a dialog to the user prompting to specify an output name.
  private static void export_dialog( MainWindow win, ExportType export_type, Note? note, NoteItem? item ) {

    var filter = new FileFilter();
    filter.name = export_type.label();
    filter.add_suffix( export_type.extension() );

    var filename = "unnamed." + export_type.extension();

    var dialog = Utils.make_file_chooser( _( "Export" ), _( "Export" ) );

    dialog.default_filter = filter;
    dialog.initial_name = filename;

    dialog.save.begin( win, null, (obj, res) => {
      try {
        var file = dialog.save.end( res );
        if( file != null ) {
          if( export_type == ExportType.TEXTBUNDLE ) {
            var tb = new TextBundle( win );
            if( note != null ) {
              tb.export_note( note, file.get_path() );
            } else if( item != null ) {
              tb.export_note_item( item, file.get_path() );
            }
          } else {
            var langs    = new Gee.HashSet<string>();
            var markdown = "";
            if( note != null ) {
              markdown = note.to_markdown( win.notebooks, true, (export_type != ExportType.MARKDOWN) );
              note.get_needed_languages( langs );
              do_export( win, export_type, file.get_path(), markdown, langs );
            } else if( item != null ) {
              markdown = item.to_markdown( win.notebooks, true );
              if( item.item_type == NoteItemType.CODE ) {
                langs.add( ((NoteItemCode)item).lang );
              }
              do_export( win, export_type, file.get_path(), markdown, langs );
            }
          }
        }
      } catch( Error e ) {}
    });

  }

  //-------------------------------------------------------------
  // Performs the export operation.
  private static bool do_export( MainWindow win, ExportType export_type, string filename, string markdown, Gee.HashSet<string> needed_langs ) {

    var file_parts   = filename.split( "." );
    var extension    = file_parts[file_parts.length-1];
    var ext_filename = filename + ((extension == export_type.extension()) ? "" : ("." + export_type.extension()));
    var md_filename  = filename + ((extension == "md") ? "" : ".md");
    var lang_dir     = "";

    // Write the note contents to a file
    try {
      FileUtils.set_contents( md_filename, markdown );
    } catch( FileError e ) {
      stdout.printf( "ERROR:  %s\n", e.message );
      return( false );
    }

    // If we don't need to run pandoc, return immediately
    if( export_type == ExportType.MARKDOWN ) {
      return( true );
    }

    // Find the directory that contains the pandoc languages
    foreach( var data_dir in Environment.get_system_data_dirs() ) {
      lang_dir = GLib.Path.build_filename( data_dir, "mosaic-note", "pandoc-langs" );
      if( FileUtils.test( lang_dir, FileTest.EXISTS ) ) {
        break;
      }
    }

    // Call pandoc (use async method) to generate the documentation
    try {

      string[] command = {};
      command += "pandoc";

      // Figure out which languages we need to add to Pandoc
      if( lang_dir != "" ) {
        needed_langs.foreach((lang) => {
          var lang_file = Path.build_filename( lang_dir, lang + ".xml" );
          if( FileUtils.test( lang_file, FileTest.EXISTS ) ) {
            command += "--syntax-definition";
            command += lang_file;
          }    
          return( true );
        });
      }

      command += "-f";

      // Added extensions:
      // +mark = Adds support for highlighting text surrounded by "=="
      command += "markdown+mark";
      command += "--embed-resources";
      command += "--standalone";
      command += "-o";
      command += ext_filename;
      command += md_filename;

      Process.spawn_command_line_async( string.joinv( " ", command ) );

    } catch( SpawnError e ) {
      stdout.printf( "ERROR:  %s\n", e.message );
      FileUtils.remove( md_filename );
      return( false );
    }

    return( true );

  }

}
