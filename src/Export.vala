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
  HTML,
  LATEX,
  PDF,
  EPUB,
  DOCX,
  PPTX,
  ODT,
  RTF,
  TEXT,
  JSON,
  YAML,
  NUM;

  public string to_string() {
    switch( this ) {
      case MARKDOWN :  return( "markdown" );
      case HTML     :  return( "html" );
      case LATEX    :  return( "latex" );
      case PDF      :  return( "pdf" );
      case EPUB     :  return( "epub" );
      case DOCX     :  return( "docx" );
      case PPTX     :  return( "pptx" );
      case ODT      :  return( "odt" );
      case RTF      :  return( "rtf" );
      case TEXT     :  return( "text" );
      case JSON     :  return( "json" );
      case YAML     :  return( "yaml" );
      default       :  assert_not_reached();
    }
  }

  public string label() {
    switch( this ) {
      case MARKDOWN :  return( _( "Markdown" ) );
      case HTML     :  return( _( "HTML" ) );
      case LATEX    :  return( _( "Latex" ) );
      case PDF      :  return( _( "PDF" ) );
      case EPUB     :  return( _( "EPub" ) );
      case DOCX     :  return( _( "Microsoft Word" ) );
      case PPTX     :  return( _( "Microsoft PowerPoint" ) );
      case ODT      :  return( _( "ODT" ) );
      case RTF      :  return( _( "Rich Text Format" ) );
      case TEXT     :  return( _( "Plain Text" ) );
      case JSON     :  return( _( "JSON" ) );
      case YAML     :  return( _( "YAML" ) );
      default       :  assert_not_reached();
    }
  }

  public static ExportType parse( string val ) {
    switch( val ) {
      case "markdown" :  return( MARKDOWN );
      case "html"     :  return( HTML );
      case "latex"    :  return( LATEX );
      case "pdf"      :  return( PDF );
      case "epub"     :  return( EPUB );
      case "docx"     :  return( DOCX );
      case "pptx"     :  return( PPTX );
      case "odt"      :  return( ODT );
      case "rtf"      :  return( RTF );
      case "text"     :  return( TEXT );
      case "json"     :  return( JSON );
      case "yaml"     :  return( YAML );
      default         :  return( MARKDOWN );
    }
  }

  public string extension() {
    switch( this ) {
      case MARKDOWN :  return( "md" );
      case HTML     :  return( "html" );
      case LATEX    :  return( "latex" );
      case PDF      :  return( "pdf" );
      case EPUB     :  return( "epub" );
      case DOCX     :  return( "docx" );
      case PPTX     :  return( "pptx" );
      case ODT      :  return( "odt" );
      case RTF      :  return( "rtf" );
      case TEXT     :  return( "txt" );
      case JSON     :  return( "json" );
      case YAML     :  return( "yml" );
      default       :  assert_not_reached();
    }
  }

}

public class Export {

  //-------------------------------------------------------------
  // Exports the given note using the specified export type.
  public static void export_note( MainWindow win, ExportType export_type, Note note ) {
    var markdown = note.to_markdown( true, (export_type != ExportType.MARKDOWN) );
    var langs    = new Gee.HashSet<string>();
    note.get_needed_languages( langs );
    export_dialog( win, export_type, markdown, langs );
  }

  //-------------------------------------------------------------
  // Exports the given note item using the specified export type.
  public static void export_note_item( MainWindow win, ExportType export_type, NoteItem item ) {
    var markdown = item.to_markdown( true );
    var langs    = new Gee.HashSet<string>();
    if( item.item_type == NoteItemType.CODE ) {
      langs.add( ((NoteItemCode)item).lang );
    }
    export_dialog( win, export_type, markdown, langs );
  }

  //-------------------------------------------------------------
  // Displays a dialog to the user prompting to specify an output name.
  private static void export_dialog( MainWindow win, ExportType export_type, string markdown, Gee.HashSet<string> needed_langs ) {

    var filter = new FileFilter();
    filter.name = export_type.label();
    filter.add_suffix( export_type.extension() );

    var filename = "unnamed." + export_type.extension();

#if GTK410
    var dialog = Utils.make_file_chooser( _( "Export" ), _( "Export" ) );

    dialog.default_filter = filter;
    dialog.initial_name = filename;

    dialog.save.begin( win, null, (obj, res) => {
      try {
        var file = dialog.save.end( res );
        if( file != null ) {
          do_export( export_type, file.get_path(), markdown, needed_langs );
        }
      } catch( Error e ) {}
    });
#else
    var dialog = Utils.make_file_chooser( _( "Export" ), win, FileChooserAction.SAVE, _( "Export" ) );

    dialog.filter = filter;
    dialog.set_current_name( filename );

    dialog.response.connect((id) => {
      if( id == ResponseType.ACCEPT ) {
        var file = dialog.get_file();
        if( file != null ) {
          do_export( export_type, file.get_path(), markdown, needed_langs );
        }
      }
      dialog.destroy();
    });

    dialog.show();
#endif

  }

  //-------------------------------------------------------------
  // Performs the export operation.
  private static bool do_export( ExportType export_type, string filename, string markdown, Gee.HashSet<string> needed_langs ) {

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

      command += "--self-contained";
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