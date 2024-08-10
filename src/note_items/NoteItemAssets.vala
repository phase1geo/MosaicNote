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

public class NoteItemAssets : NoteItem {

  private Array<string> _assets;

  //-------------------------------------------------------------
	// Default constructor
	public NoteItemAssets( Note note ) {
		base( note, NoteItemType.ASSETS );
    _assets = new Array<string>();
	}

  //-------------------------------------------------------------
	// Constructor from XML node
	public NoteItemAssets.from_xml( Note note, Xml.Node* node ) {
		base( note, NoteItemType.ASSETS );
    _assets = new Array<string>();
		load( node );
	}

  //-------------------------------------------------------------
	// Copies the note item to this one
  public override void copy( NoteItem item ) {
    base.copy( item );
    var other = (item as NoteItemAssets);
    if( (other != null) && (other.size() > 0) ) {
      for( int i=0; i<other.size(); i++ ) {
        _assets.append_val( other.get_asset( i ) );
      }
    }
  }

  //-------------------------------------------------------------
  // Returns the number of stored assets.
  public int size() {
    return( (int)_assets.length );
  }

  //-------------------------------------------------------------
  // Returns the asset at the given index.
  public string get_asset( int index ) {
    return( _assets.index( index ) );
  }

  //-------------------------------------------------------------
  // Adds the given asset to our list.
  public void add_asset( string asset ) {
    _assets.append_val( asset );
    modified = true;
    changed();
  }

  //-------------------------------------------------------------
  // Removes the asset at the given index.
  public void remove_asset( int index ) {
    _assets.remove_index( index );
    modified = true;
    changed();
  }

  //-------------------------------------------------------------
  // Returns the Markdown version of this item
  public override string to_markdown( bool pandoc ) {
    string[] str = {};
    for( int i=0; i<_assets.length; i++ ) {
      var asset = _assets.index( i );
    	str += "- [%s](%s)".printf( Filename.display_basename( asset ), asset );
  	}
  	return( string.joinv( "\n", str ) );
  }

  //-------------------------------------------------------------
	// Saves the content in XML format
	public override Xml.Node* save() {
    Xml.Node* node = base.save();
    for( int i=0; i<_assets.length; i++ ) {
      Xml.Node* asset = new Xml.Node( null, "asset" );
      asset->set_prop( "path", _assets.index( i ) );
      node->add_child( asset );
    }
    return( node );
	}

  //-------------------------------------------------------------
	// Loads the content from XML format
	protected override void load( Xml.Node* node ) {
    base.load( node );
    for( Xml.Node* it = node->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "asset") ) {
        var p = it->get_prop( "path" );
        if( p != null ) {
          _assets.append_val( p );
        }
      }
    }
	}

}