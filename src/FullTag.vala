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

using Gee;

public class FullTag : BaseNotebook {

	private NotebookTree _notebooks;

	public HashSet<int> notes { get; private set; }

	// Default constructor
	public FullTag( string tag_name, NotebookTree notebooks ) {
		base( tag_name );
    notes = new HashSet<int>();
    _notebooks = notebooks;
	}

	// Constructor from XML format
	public FullTag.from_xml( Xml.Node* node, NotebookTree notebooks ) {
		base( "" );
    notes = new HashSet<int>();
    _notebooks = notebooks;
		load( node );
	}

	// Comparison function for searching
	public bool matches( string name ) {
		return( this.name == name );
	}

	// Adds a note ID to the list
	public void add_note_id( int id ) {
		notes.add( id );
	}

	// Removes the given note ID to the list
	public void remove_note_id( int id ) {
		notes.remove( id );
	}

	// Returns the number of notes with this tag
	public override int count() {
		return( notes.size );
	}

	// Returns the list model required by the NotesPanel
  public override ListModel? get_model() {

    var list = new ListStore( typeof(Note) );

    notes.foreach((id) => {
      list.append( _notebooks.find_note_by_id( id ) );
      return( true );
    });

    return( list );

  }

	// Saves the contents of this tag in XML format
	public Xml.Node* save() {
		Xml.Node* node = new Xml.Node( null, "tag" );
		string[]  ids  = {};
		notes.foreach((id) => {
			ids += id.to_string();
			return( true );
  	});
		base_save( node );
		node->set_prop( "ids", string.joinv( ",", ids ) );
		return( node );
	}

	// Loads the contents of this tag from XML format
	public void load( Xml.Node* node ) {
		base_load( node );
	  var i = node->get_prop( "ids" );
	  if( i != null ) {
	  	foreach( var id in i.split( "," ) ) {
	  		notes.add( int.parse( id ) );
	  	}
	  }
	}

}