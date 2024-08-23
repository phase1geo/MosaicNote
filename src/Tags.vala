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

public class Tags {

	private Array<string> _tags;

	// Default constructor
	public Tags() {
		_tags = new Array<string>();
	}

	// Constructor from XML
	public Tags.from_xml( Xml.Node* node ) {
		_tags = new Array<string>();
		load( node );
	}

	// Copies the given Tags object to this object
	public void copy( Tags tags ) {
		_tags.remove_range( 0, _tags.length );
		for( int i=0; i<tags._tags.length; i++ ) {
			_tags.append_val( tags._tags.index( i ) );
		}
	}

	// Size of the tag list
	public int size() {
		return( (int)_tags.length );
	}

	// Returns the tag at the given position
	public string get_tag( int pos ) {
		return( _tags.index( pos ) );
	}

	// Returns true if the list of tags contains the given tag
	public bool contains_tag( string tag ) {
		for( int i=0; i<_tags.length; i++ ) {
			if( tag == _tags.index( i ) ) {
				return( true );
			}
		}
		return( false );
	}

	// Adds the tag if it is unique to this list
	public void add_tag( string tag ) {
		if( !contains_tag( tag ) ) {
			_tags.append_val( tag );
		}
	}

	// Removes the tag from the given list if it exists
	public void delete_tag( string tag ) {
		for( int i=0; i<_tags.length; i++ ) {
			if( tag == _tags.index( i ) ) {
        stdout.printf( "Removing tag: %s at index: %d\n", tag, i );
				_tags.remove_index( i );
				return;
			}
		}
	}

	// Removes all of the tags
	public void clear() {
		_tags.remove_range( 0, _tags.length );
	}

	// Returns string version of tags to be used in Markdown YAML front-matter
	public string to_markdown() {
    string[] tags = {};
    for( int i=0; i<_tags.length; i++ ) {
    	tags += "\"" + _tags.index( i ) + "\"";
    }
    return( string.joinv( ",", tags ) );
	}

	// Saves the tags in XML format
	public Xml.Node* save() {
		Xml.Node* node = new Xml.Node( null, "tags" );
		for( int i=0; i<_tags.length; i++ ) {
			Xml.Node* tag = new Xml.Node( null, "tag" );
			tag->set_prop( "name", _tags.index( i ) );
			node->add_child( tag );
		}
		return( node );
	}

	// Loads the tags from XML format
	public void load( Xml.Node* node ) {
		for( Xml.Node* it = node->children; it != null; it = it->next ) {
			if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "tag") ) {
				var n = it->get_prop( "name" );
				if( n != null ) {
					_tags.append_val( n );
				}
			}
		}
	}

}