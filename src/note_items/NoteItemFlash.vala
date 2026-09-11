/*
* Copyright (c) 2024-2026 (https://github.com/phase1geo/MosaicNote)
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

public class NoteItemFlashCard {

  private string _side1;
  private string _side2;

  public string side1 {
    get {
      return( _side1 );
    }
  }

  public string side2 {
    get {
      return( _side2 );
    }
  }

  //-------------------------------------------------------------
  // Default constructor.
  public NoteItemFlashCard( string side1, string side2 ) {
    _side1 = side1;
    _side2 = side2;
  }

  //-------------------------------------------------------------
  // Creates a new flash card from the given XML node.
  public NoteItemFlashCard.from_xml( Xml.Node* node ) {
    load( node );
  }

  //-------------------------------------------------------------
  // Returns true if either side1 or side2 matches the given string.
  public bool contains( string str ) {
    return( side1.contains( str ) || side2.contains( str ) );
  }

  //-------------------------------------------------------------
  // Saves the content of this card in a node called "card".
  public Xml.Node* save() {
    Xml.Node* node  = new Xml.Node( null, "card" );
    Xml.Node* node1 = new Xml.Node( null, "side1" );
    Xml.Node* node2 = new Xml.Node( null, "side2" );
    node1->set_content( side1 );
    node2->set_content( side2 );
    node->add_child( node1 );
    node->add_child( node2 );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads the contents of this card from the XML node called "card".
  private void load( Xml.Node* node ) {
    for( Xml.Node* it = node->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "side1" :  _side1 = it->get_content();  break;
          case "side2" :  _side2 = it->get_content();  break;
          default      :  assert_not_reached();
        }
      }
    }
  }

}

public class NoteItemFlash : NoteItem {

  private Array<NoteItemFlashCard> _cards;
  private string _description = "";

  public string description {
    get {
      return( _description );
    }
    set {
      if( _description != value ) {
        _description = value;
        modified = true;
        changed();
      }
    }
  }

  //-------------------------------------------------------------
	// Default constructor
	public NoteItemFlash( NoteItemRow row ) {
		base( row, NoteItemType.FLASH );
    _cards = new Array<NoteItemFlashCard>();
	}

  //-------------------------------------------------------------
	// Constructor from XML node
	public NoteItemFlash.from_xml( NoteItemRow row, Xml.Node* node ) {
		base( row, NoteItemType.FLASH );
    _cards = new Array<NoteItemFlashCard>();
		load( node );
	}

  //-------------------------------------------------------------
	// Copies the note item to this one
  public override void copy( NoteItem item ) {
    base.copy( item );
    var other = (item as NoteItemFlash);
    if( (other != null) && (other.size() > 0) ) {
      for( int i=0; i<other.size(); i++ ) {
        _cards.append_val( other.get_card( i ) );
      }
    }
  }

  //-------------------------------------------------------------
  // Returns the number of stored assets.
  public int size() {
    return( (int)_cards.length );
  }

  //-------------------------------------------------------------
  // Returns the asset at the given index.
  public NoteItemFlashCard get_card( int index ) {
    return( _cards.index( index ) );
  }

  //-------------------------------------------------------------
  // Adds the given asset to our list.
  public void add_card( string side1, string side2, int index = -1 ) {
    var card = new NoteItemFlashCard( side1, side2 );
    if( index == -1 ) {
      _cards.append_val( card );
    } else {
      _cards.insert_val( index, card );
    }
    modified = true;
    changed();
  }

  //-------------------------------------------------------------
  // Inserts a flash card that already existed (used by undo system).
  public void insert_existing_card( int index, NoteItemFlashCard card ) {
    _cards.insert_val( index, card );
  }

  //-------------------------------------------------------------
  // Removes the asset at the given index.
  public void remove_card( int index ) {
    _cards.remove_index( index );
    modified = true;
    changed();
  }

  //-------------------------------------------------------------
  // Used for string searching
  public override bool search( string str ) {
    for( int i=0; i<_cards.length; i++ ) {
      if( _cards.index( i ).contains( str ) ) {
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns the title to display for pandoc.
  public override string pandoc_title() {
    if( description != "" ) {
      return( description );
    } else {
      return( base.pandoc_title() );
    }
  }

  //-------------------------------------------------------------
  // Returns the Markdown version of this item
  public override string to_markdown( NotebookTree? notebooks, bool include_footnotes, bool pandoc, bool presenter ) {
    string str = "";
    for( int i=0; i<_cards.length; i++ ) {
      var card = _cards.index( i );
      str += "%s\n: %s\n\n".printf( card.side1, card.side2 );
    }
  	return( str );
  }

  //-------------------------------------------------------------
  // Returns the Markdown version of this item.
  public override string export( NotebookTree? notebooks, bool include_footnotes, string assets_dir ) {
    return( to_markdown( notebooks, include_footnotes, false, false ) );
  }

  //-------------------------------------------------------------
	// Saves the content in XML format
	public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "description", description );
    for( int i=0; i<_cards.length; i++ ) {
      node->add_child( _cards.index( i ).save() );
    }
    return( node );
	}

  //-------------------------------------------------------------
	// Loads the content from XML format
	protected override void load( Xml.Node* node ) {
    base.load( node );
    var d = node->get_prop( "description" );
    if( d != null ) {
      description = d;
    }
    for( Xml.Node* it = node->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "card") ) {
        var card = new NoteItemFlashCard.from_xml( it );
        _cards.append_val( card );
      }
    }
	}

}
