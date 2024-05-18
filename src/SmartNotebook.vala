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

public class SmartNotebook {

  Array<SmartFilter> _filters;
  Gee.HashSet<int>   _notes;

  bool _modified = false;

  // Default constructor
  public SmartNotebook() {
    _filters = new Array<SmartFilter>();
    _notes   = new Gee.HashSet<int>();
  }

  // Constructor from XML data
  public SmartNotebook.from_xml( Xml.Node* node ) {
    _filters = new Array<SmartFilter>();
    _notes   = new Gee.HashSet<int>();

    load( node );
  }

  // Returns the number of matched notes
  public int count() {
    return( _notes.size );
  }

  // Checks the given note to see if this notebook should
  // add support for this note
  public bool handle_note( Note note ) {

    bool modified = false;

    // Check to see if the note passes all of the stored filters
    for( int i=0; i<_filters.length; i++ ) {
      if( !_filters.index( i ).check_note( note ) ) {
        modified = _notes.remove( note.id );
        _modified |= modified;
        return( modified );
      }
    }

    // If all of the filters passed, add the note ID if it doesn't already exist
    modified = _notes.add( note.id );
    _modified |= modified;

    return( modified );

  }

  // Saves the smartbook in XML format
  public Xml.Node* save() {

    Xml.Node* node = new Xml.Node( null, "smart-notebook" );
    string[]  ids  = {};

    // Convert the stored note IDs as a comma-separated string
    _notes.foreach((id) => {
      ids += id.to_string();
      return( true );
    });

    node->set_prop( "ids", string.joinv( ",", ids ) );

    for( int i=0; i<_filters.length; i++ ) {
      node->add_child( _filters.index( i ).save() );
    }

    _modified = false;

    return( node );

  }

  // Loads the contents of this smart folder from XML format
  public void load( Xml.Node* node ) {

    var i = node->get_prop( "ids" );
    if( i != null ) {
      var ids = i.split( "," );
      foreach( var id in ids ) {
        _notes.add( int.parse( id ) );
      }
    }

    for( Xml.Node* it = node->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "smart-filter") ) {
        var filter = new SmartFilter.from_xml( it );
        _filters.append_val( filter );
      }
    }

  }

}