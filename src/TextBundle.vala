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
  public void import( string filename ) {

    var directory_path = filename;

    try {

      var directory  = File.new_for_path( directory_path );
      var enumerator = directory.enumerate_children( "standard::*", FileQueryInfoFlags.NONE );

      FileInfo? info;
      while( (info = enumerator.next_file()) != null ) {
        string name = info.get_name();
        if( info.get_file_type() == FileType.REGULAR ) {
          if( name.has_prefix( "test." ) && (name.has_suffix( ".markdown" ) || name.has_suffix( ".md" )) ) {
            import_markdown( name );
          }
        }
      }
      enumerator.close();
    } catch( Error e ) {
        stderr.printf("Error: %s\n", e.message);
    }

  }

  private void import_markdown( string filename ) {

    // TODO

  }

  //=============================================================

  //-------------------------------------------------------------
  // Exports
  public void export( string filename ) {
    // TODO
  }

}