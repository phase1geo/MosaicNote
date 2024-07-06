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

public class Favorite : Object {

	private bool _nb = false;
	private int  _id = -1;

	public bool notebook {
		get {
			return( _nb );
		}
	}

	public int id {
		get {
			return( _id );
		}
	}

	// Default constructor
	public Favorite( bool notebook, int id ) {
		_nb = notebook;
		_id = id;
	}

	// Constructor from XML
	public Favorite.from_xml( Xml.Node* node ) {
		load( node );
	}

	// Returns the name of the notebook or title of the note that represents this favorite
	public string? get_name( NotebookTree notebooks ) {
		if( _nb ) {
			var nb = notebooks.find_notebook( _id );
			if( nb != null ) {
        return( nb.name );
			}
		} else {
			var note = notebooks.find_note_by_id( _id );
			if( note != null ) {
				return( note.title );
			}
		}
		return( null );
	}

	// Save the contents of this favorite to XML format
	public Xml.Node* save() {

    Xml.Node* node = new Xml.Node( null, "favorite" );	

  	node->set_prop( "notebook", _nb.to_string() );
		node->set_prop( "id", _id.to_string() );

		return( node );

	}

	// Loads the contents of the favorite from XML format
	private void load( Xml.Node* node ) {

		var n = node->get_prop( "notebook" );
		if( n != null ) {
			_nb = bool.parse( n );
		}

		var i = node->get_prop( "id" );
		if( i != null ) {
			_id = int.parse( i );
		}

	}

}