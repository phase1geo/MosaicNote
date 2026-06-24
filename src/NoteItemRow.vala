/*
* Copyright (c) 2026 (https://github.com/phase1geo/Minder)
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

public class NoteItemRow : Object {

  private Note            _note;
  private Array<NoteItem> _items;
  private bool            _expanded = true;
  private bool            _modified = false;

  public Note note {
    get {
      return( _note );
    }
  }

  public bool expanded {
    get {
      return( _expanded );
    }
    set {
      if( _expanded != value ) {
        _expanded = value;
        _modified = true;
      }
    }
  }

  public bool modified {
    get {
      return( _modified );
    }
  }

  //-------------------------------------------------------------
  // Default constructor
  public NoteItemRow( Note note ) {
    _note  = note;
    _items = new Array<NoteItem>();
  }

  //-------------------------------------------------------------
  // Constructor from XML node
  public NoteItemRow.from_xml( Note note, Xml.Node* node ) {
    _note  = note;
    _items = new Array<NoteItem>();
    load( node );
  }

  //-------------------------------------------------------------
  // Copy constructor
  public NoteItemRow.copy( NoteItemRow row ) {
    _note     = row.note;
    _expanded = row.expanded;
    _items    = new Array<NoteItem>();
    for( int i=0; i<row.size(); i++ ) {
      var other_item = row.get_item( i );
      var new_item   = other_item.item_type.create( this );
      new_item.copy( other_item );
      _items.append_val( new_item );
    }
  }

  //-------------------------------------------------------------
  // Returns the number of items in the row.
  public int size() {
    return( (int)_items.length );
  }

  //-------------------------------------------------------------
  // Returns the item at the given column index.
  public NoteItem get_item( int col ) {
    return( _items.index( col ) );
  }

  //-------------------------------------------------------------
  // Returns the column position of the given item in the row.
  // If it doesn't exist, returns -1.
  public int get_column( NoteItem item ) {
    for( int i=0; i<_items.length; i++ ) {
      if( _items.index( i ) == item ) {
        return( i );
      }
    }
    return( -1 );
  }

  //-------------------------------------------------------------
  // Adds the given item at the specified column.  If col is -1,
  // appends the column to the end.
  public void add_item( NoteItem item, int col = -1 ) {
    if( col == -1 ) {
      _items.append_val( item );
    } else {
      _items.insert_val( (uint)col, item );
    }
    _modified = true;
  }

  //-------------------------------------------------------------
  // Removes the item at the given column index.
  public void delete_item( int col ) {
    _items.remove_index( col );
    _modified = true;
  }

  //-------------------------------------------------------------
  // Moves the item located at the old column to the new column.
  public void move_item( int old_col, int new_col ) {
    if( old_col != new_col ) {
      if( old_col < new_col ) {
        new_col++;
      }
      var item = _items.index( old_col );
      _items.remove_index( old_col );
      _items.insert_val( new_col, item );
      _modified = true;
    }
  }

  //-------------------------------------------------------------
  // Converts the current note item to the specified item and stores this
  // new item in its place.
  public void convert_note_item( int col, NoteItem to_item ) {
    to_item.copy( get_item( col ) );
    _items.data[col] = to_item;
    _modified = true;
  }

  //-------------------------------------------------------------
  // Saves the contents of this row as an XML node and returns it
  // to the calling function.
  public Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "row" );
    node->set_prop( "expanded", expanded.to_string() );
    for( int i=0; i<_items.length; i++ ) {
      node->add_child( _items.index( i ).save() );
    }
    _modified = false;
    return( node );
  }

  //-------------------------------------------------------------
  // Loads the contents of the given XML node into this class.
  public void load( Xml.Node* node ) {
    var e = node->get_prop( "expanded" );
    if( e != null ) {
      _expanded = bool.parse( e );
    }
    for( Xml.Node* it = node->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        var type = NoteItemType.parse( it->name );
        switch( type ) {
          case NoteItemType.MARKDOWN :  load_markdown_item( it );  break;
          case NoteItemType.CODE     :  load_code_item( it );      break;
          case NoteItemType.IMAGE    :  load_image_item( it );     break;
          case NoteItemType.UML      :  load_uml_item( it );       break;
          case NoteItemType.MATH     :  load_math_item( it );      break;
          case NoteItemType.TABLE    :  load_table_item( it );     break;
          case NoteItemType.ASSETS   :  load_assets_item( it );    break;
          default                    :  break;
        }
      }
    }
  }

  //-------------------------------------------------------------
  // Loads a markdown item from XML data
  private void load_markdown_item( Xml.Node* node ) {
    var item = new NoteItemMarkdown.from_xml( this, node );
    _items.append_val( item );
  }

  //-------------------------------------------------------------
  // Loads a code item from XML data
  private void load_code_item( Xml.Node* node ) {
    var item = new NoteItemCode.from_xml( this, node );
    _items.append_val( item );
  }

  //-------------------------------------------------------------
  // Loads an image item from XML data
  private void load_image_item( Xml.Node* node ) {
    var item = new NoteItemImage.from_xml( this, node );
    _items.append_val( item );
  }

  //-------------------------------------------------------------
  // Loads a UML item from XML data
  private void load_uml_item( Xml.Node* node ) {
    var item = new NoteItemUML.from_xml( this, node );
    _items.append_val( item );
  }

  //-------------------------------------------------------------
  // Loads a math formula from XML data
  private void load_math_item( Xml.Node* node ) {
    var item = new NoteItemMath.from_xml( this, node );
    _items.append_val( item );
  }

  //-------------------------------------------------------------
  // Loads a table item from XML data
  private void load_table_item( Xml.Node* node ) {
    var item = new NoteItemTable.from_xml( this, node );
    _items.append_val( item );
  }

  //-------------------------------------------------------------
  // Loads an asset item from XML data
  private void load_assets_item( Xml.Node* node ) {
    var item = new NoteItemAssets.from_xml( this, node );
    _items.append_val( item );
  }


}
