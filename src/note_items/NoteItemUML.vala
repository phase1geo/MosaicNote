/*
* Copyright (c) 2024 (https://github.com/phase1geo/MosaicNote)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
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

public class NoteItemUML : NoteItem {

	public signal void diagram_updated( string? filename );

	// Default constructor
	public NoteItemUML() {
		base( NoteItemType.UML );
		changed.connect( update_diagram );
	}

	public NoteItemUML.from_xml( Xml.Node* node ) {
		base( NoteItemType.UML );
		load( node );
		changed.connect( update_diagram );
	}

	// Updates the UML diagram
	public void update_diagram() {

	  var input  = Utils.user_location( "test.txt" );
	  var output = Utils.user_location( "test.png" );

		// Save the current content to a file
		try {
			FileUtils.set_contents( input, content );
		} catch( FileError e ) {
			stdout.printf( "Error saving UML diagrame contents to file %s: %s\n", input, e.message );
			diagram_updated( null );
			return;
		}

    try {
    	var command = "plantuml %s".printf( input );
    	Process.spawn_command_line_sync( command );
    	if( FileUtils.test( output, FileTest.EXISTS ) ) {
    		diagram_updated( output );
    		return;
    	}
    } catch( SpawnError e ) {
    	stdout.printf( "Error generating PlantUML diagram %s: %s\n", input, e.message );
    }

    diagram_updated( null );

	}

}