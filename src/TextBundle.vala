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

public class TextBundle {

  private MainWindow _win;

  //-------------------------------------------------------------
  // Default constructor
  public TextBundle( MainWindow win ) {
    _win = win;
  }

  //-------------------------------------------------------------
  // Imports a TextBundle of the given name.
  public void import( Notebook notebook, string filename ) {

    var directory_path = filename;

    try {

      var directory  = File.new_for_path( directory_path );
      var enumerator = directory.enumerate_children( "standard::*", FileQueryInfoFlags.NONE );

      FileInfo? info;
      while( (info = enumerator.next_file()) != null ) {
        string name = info.get_name();
        if( info.get_file_type() == FileType.REGULAR ) {
          if( name.has_prefix( "test." ) && (name.has_suffix( ".markdown" ) || name.has_suffix( ".md" )) ) {
            import_markdown( notebook, name );
            break;
          }
        }
      }
      enumerator.close();
    } catch( Error e ) {
        stderr.printf("Error: %s\n", e.message);
    }

  }

  //-------------------------------------------------------------
  // Import the Markdown file.
  private void import_markdown( Notebook notebook, string filename ) {

    try {

      string contents;
      FileUtils.get_contents( filename, out contents );

      var parser = new NoteParser();
      var note   = parser.parse_markdown( notebook, contents );
      notebook.add_note( note );

      // Display the newly imported note
      _win.show_note( note.id );

    } catch( FileError e ) {

    }

  }

  //=============================================================

  //-------------------------------------------------------------
  // Exports the given note in TextBundle format.
  public void export_note( Note note, string dirname ) throws FileError {
    try {
      var tmp_dir    = DirUtils.make_tmp( "tbXXXXXX" );
      var assets_dir = Path.build_filename( tmp_dir, "assets" );

      Utils.create_dir( assets_dir );
      
      export_info( tmp_dir );
      export_markdown_note( note, tmp_dir, assets_dir );

      move_directory( tmp_dir, dirname );
    } catch( FileError e ) {}
  }

  //-------------------------------------------------------------
  // Exports the given note item in TextBundle format.
  public void export_note_item( NoteItem item, string dirname ) throws FileError {
    try {
      var tmp_dir    = DirUtils.make_tmp( "tbXXXXXX" );
      var assets_dir = Path.build_filename( tmp_dir, "assets" );

      Utils.create_dir( assets_dir );

      export_info( tmp_dir );
      export_markdown_item( item, tmp_dir, assets_dir );

      move_directory( tmp_dir, dirname );
    } catch( FileError e ) {}
  }

  //-------------------------------------------------------------
  // Moves the temporary directory to the user-selected directory
  // name.
  private void move_directory( string from_dir, string to_dir ) {
    try {
      var src = File.new_for_path( from_dir );
      var dst = File.new_for_path( to_dir );
      src.move( dst, FileCopyFlags.NONE );
    } catch( Error e ) {}
  }
  
  //-------------------------------------------------------------
  // Exports TextBundle info.json file contents to the specified
  // directory.
  private void export_info( string dirname ) throws FileError {
    
    var filename = Path.build_filename( dirname, "info.json" );
    
    var contents = """
    {
      "version":              2,
      "type":                 "net.daringfireball.markdown",
      "transient":            true,
      "creatorIdentifier":    "com.github.phase1geo.mosaic-note"
    }
    """;
    
    FileUtils.set_contents( filename, contents );
    
  }

  //-------------------------------------------------------------
  // Exports the note im Markdown format, adding note assets
  // to the given assets directory.
  private void export_markdown_note( Note note, string dirname, string assets_dir ) throws FileError {
    
    var filename = Path.build_filename( dirname, "text.md" );
    note.export( _win.notebooks, filename, assets_dir );
    
  }

  //-------------------------------------------------------------
  // Exports the note item in Markdown format, adding item assets
  // to the given assets directory.
  private void export_markdown_item( NoteItem item, string dirname, string assets_dir ) throws FileError {

    var filename = Path.build_filename( dirname, "text.md" );
    var markdown = item.export( _win.notebooks, assets_dir );

    FileUtils.set_contents( filename, markdown );

  }
  
}