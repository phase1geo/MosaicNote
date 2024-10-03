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

using Gee;

public class Gallery : BaseNotebook {

  private NotebookTree _notebooks;
  private HashSet<int> _item_id;
  private NoteItemType _item_type;

  //-------------------------------------------------------------
  // Default constructor
  public Gallery( NotebookTree notebooks, NoteItemType item_type ) {
    base( item_type.label() );
    _item_id   = new HashSet<int>();
    _notebooks = notebooks;
    _item_type = item_type;
  }

  //-------------------------------------------------------------
  // Constructor from XML.
  public Gallery.from_xml( NotebookTree notebooks, Xml.Node* node ) {
    base( "" );
    _item_id   = new HashSet<int>();
    _notebooks = notebooks;
    load( node );
  }

  //-------------------------------------------------------------
  // Returns the number of tracked items in this gallery
  public override int count() {
    stdout.printf( "In gallery.count, name: %s, size: %d\n", _item_type.label(), _item_id.size );
    return( _item_id.size );
  }

  //-------------------------------------------------------------
  // Populates the array with the given note items that are tracked
  // by this gallery.
  public void get_note_items( Array<NoteItem> items ) {
    _item_id.foreach((id) => {
      var item = _notebooks.find_note_item( id );
      if( item != null ) {
        items.append_val( item );
      }
      return( true );
    });
  }

  //-------------------------------------------------------------
  // Called before the given note is deleted.  Removes any
  // matching note items within the note from our tracked list.
  public void remove_note( Note note ) {
    var modified = false;
    for( int i=0; i<note.size(); i++ ) {
      var item = note.get_item( i );
      if( _item_id.remove( item.id ) ) {
        modified = true;
      }
    }
    if( modified ) {
      changed();
    }
  }

  //-------------------------------------------------------------
  // Removes a specific note item from our list
  public void remove_note_item( NoteItem item ) {
    if( _item_id.remove( item.id ) ) {
      changed();
    }
  }

  //-------------------------------------------------------------
  // Handles any changes to the the note items within a given note.
  public void handle_note( Note note ) {
    var modified = false;
    for( int i=0; i<note.size(); i++ ) {
      var item = note.get_item( i );
      if( item.item_type == _item_type ) {
        _item_id.add( item.id );
        modified = true;
      }
    }
    if( modified ) {
      changed();
    }
  }

  //-------------------------------------------------------------
  // Saves the stored note item IDs in XML format.
  public Xml.Node* save() {

    // Convert the stored note IDs as a comma-separated string
    string[] ids  = {};
    _item_id.foreach((id) => {
      ids += id.to_string();
      return( true );
    });

    Xml.Node* node = new Xml.Node( null, "gallery" );
    node->set_prop( "type", _item_type.to_string() );
    node->set_prop( "ids", string.joinv( ",", ids ) );

    return( node );

  }

  //-------------------------------------------------------------
  // Loads the XML representation of this gallery into the class
  public void load( Xml.Node* node ) {

    var t = node->get_prop( "type" );
    if( t != null ) {
      _item_type = NoteItemType.parse( t );
      _name      = _item_type.label();
    }

    var i = node->get_prop( "ids" );
    if( i != null ) {
      var ids = i.split( "," );
      foreach( var id in ids ) {
        _item_id.add( int.parse( id ) );
      }
    }

  }

}