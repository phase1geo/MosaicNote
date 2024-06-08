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

public class Note : Object {

	public static int current_id = 0;

	private Notebook        _nb;        // done
	private int             _id;
	private string          _title;
	private DateTime        _created;   // done
	private DateTime        _updated;   // done
	private DateTime        _viewed;    // done
	private bool            _locked;
  private bool            _favorite;  // done
	private Tags            _tags;      // done
	private Array<NoteItem> _items;

	public bool modified { get; private set; default = false; }

	public Notebook notebook {
		get {
			return( _nb );
		}
	}

	public int id {
		get {
			return( _id );
		}
	}

	public string title {
		get {
			return( _title );
		}
		set {
			if( _title != value ) {
				_title = value;
				modified = true;
        title_changed();
			}
		}
	}

	public DateTime created {
		get {
			return( _created );
		}
	}

	public DateTime updated {
		get {
			return( _updated );
		}
	}

	public DateTime viewed {
		get {
			return( _viewed );
		}
	}

	public bool locked {
		get {
      return( _locked );
		}
		set {
			if( _locked != value ) {
				_locked  = value;
        modified = true;
			}
		}
	}

  public bool favorite {
    get {
      return( _favorite );
    }
    set {
      if( _favorite != value ) {
        _favorite = value;
        modified  = true;
      }
    }
  }

  public Tags tags {
    get {
      return( _tags );
    }
  }

  public signal void changed();
  public signal void title_changed();

	// Default constructor
	public Note( Notebook nb ) {
		_nb       = nb;
		_id       = current_id++;
		_title    = _( "Untitled Note" );
		_created  = new DateTime.now_local();
		_updated  = new DateTime.now_local();
		_viewed   = new DateTime.now_local();
		_locked   = false;
    _favorite = false;
		_tags     = new Tags();
    _items    = new Array<NoteItem>();

    var item = new NoteItemMarkdown( this );
    add_note_item( 0, item );
	}

	// Constructs note from XML node
	public Note.from_xml( Notebook nb, Xml.Node* node ) {
		_nb    = nb;
    _tags  = new Tags();
    _items = new Array<NoteItem>();

		load( node );
	}

	// Updates the viewed timestamp
	public void reviewed() {
		_viewed = new DateTime.now_local();
	}

  // Returns the number of note items in the array
  public int size() {
    return( (int)_items.length );
  }

  // Returns the note item at the given position
  public NoteItem get_item( int pos ) {
    return( _items.index( pos ) );
  }

	// Adds the given note item to this list of items at the given position.
	public void add_note_item( uint pos, NoteItem item ) {
		_items.insert_val( pos, item );
	}

	// Removes the note item at the given position.
	public void delete_note_item( uint pos ) {
    get_item( (int)pos ).delete_resource();
		_items.remove_index( pos );
		_modified = true;
	}

  // Moves the item at the old position to the new position in the item array.
  public void move_item( int old_pos, int new_pos ) {
    var item = _items.index( old_pos );
    _items.remove_index( old_pos );
    if( new_pos == -1 ) {
      _items.append_val( item );
    } else {
      _items.insert_val( new_pos, item );
    }
  }

  // Returns a string containing the content of the note in Markdown format
  public string to_markdown( bool pandoc = false ) {
  	var str = "---\ntitle: '%s'\ntags: [%s]\n---\n\n".printf( _title, _tags.to_markdown() );
  	str += "# %s\n\n".printf( _title );
  	for( int i=0; i<_items.length; i++ ) {
  		var item = _items.index( i );
  		str += "%s\n\n".printf( item.to_markdown( pandoc ) );
  	}
  	return( str );
  }

  // Populates the given array with the list of languages that are used by the node.
  // We use a HashSet so that the final list of languages doesn't contain any duplicates.
  public void get_needed_languages( Gee.HashSet<string> langs ) {
  	for( int i=0; i<_items.length; i++ ) {
  		var item = (_items.index( i ) as NoteItemCode);
  		if( item != null ) {
  			langs.add( item.lang );
  		}
  	}
  }

  // Converts the current note item to the specified item and stores this
  // new item in its place.
  public void convert_note_item( uint pos, NoteItem to_item ) {
    to_item.copy( get_item( (int)pos ) );
    _items.data[pos] = to_item;
    _modified = true;
  }

	// Returns the result of comparing our note to the given note
	public static int compare( Note a, Note b ) {
		return( (int)(a._id > b._id) - (int)(a._id < b._id) );
	}

	// Returns true if this note contains a tag with the given string.
	public bool contains_tag( string tag ) {
		return( _tags.contains_tag( tag ) );
	}

	// Saves the note in XML format
	public Xml.Node* save() {

		if( modified ) {
			_updated = new DateTime.now_local();
			modified = false;
		}

		Xml.Node* node  = new Xml.Node( null, "note" );
		Xml.Node* items = new Xml.Node( null, "items" );

		node->set_prop( "id",      _id.to_string() );
		node->set_prop( "title",   _title );
		node->set_prop( "created", _created.format_iso8601() );
		node->set_prop( "updated", _updated.format_iso8601() );
		node->set_prop( "viewed",  _viewed.format_iso8601() );
		node->set_prop( "locked",  _locked.to_string() );
    node->set_prop( "favorite", _favorite.to_string() );

		node->add_child( _tags.save() );

		// Save the note items
		for( int i=0; i<_items.length; i++ ) {
			items->add_child( _items.index( i ).save() );
		}
		node->add_child( items );

		modified = true;

		return( node );

	}

	// Loads the note from XML format
	private void load( Xml.Node* node ) {

		var i = node->get_prop( "id" );
		if( i != null ) {
			_id = int.parse( i );
		}

		var t = node->get_prop( "title" );
		if( t != null ) {
			title = t;
		}

		var c = node->get_prop( "created" );
		if( c != null ) {
      _created = new DateTime.from_iso8601( c, null );
		}

		var m = node->get_prop( "updated" );
		if( m != null ) {
			_updated = new DateTime.from_iso8601( m, null );
		}

		var v = node->get_prop( "viewed" );
		if( v != null ) {
			_viewed = new DateTime.from_iso8601( v, null );
		} else {
			_viewed = new DateTime.from_iso8601( _created.format_iso8601(), null );
		}

    var l = node->get_prop( "locked" );
    if( l != null ) {
      _locked = bool.parse( l );
    }

    var f = node->get_prop( "favorite" );
    if( f != null ) {
      _favorite = bool.parse( f );
    }

		for( Xml.Node* it = node->children; it != null; it = it->next ) {
			if( it->type == Xml.ElementType.ELEMENT_NODE ) {
				switch( it->name ) {
					case "tags"  :  _tags.load( it );  break;
					case "items" :  load_items( it );  break;
				}
			}
		}

	}

	private void load_items( Xml.Node* node ) {
		for( Xml.Node* it = node->children; it != null; it = it->next ) {
			if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        var type = NoteItemType.parse( it->name );
        switch( type ) {
        	case NoteItemType.MARKDOWN :  load_markdown_item( it );  break;
        	case NoteItemType.CODE     :  load_code_item( it );      break;
        	case NoteItemType.IMAGE    :  load_image_item( it );     break;
        	case NoteItemType.UML      :  load_uml_item( it );       break;
          default                    :  break;
        }
			}
		}
	}

	private void load_markdown_item( Xml.Node* node ) {
		var item = new NoteItemMarkdown.from_xml( this, node );
		_items.append_val( item );
	}

	private void load_code_item( Xml.Node* node ) {
		var item = new NoteItemCode.from_xml( this, node );
		_items.append_val( item );
	}

	private void load_image_item( Xml.Node* node ) {
		var item = new NoteItemImage.from_xml( this, node );
		_items.append_val( item );
	}

	private void load_uml_item( Xml.Node* node ) {
		var item = new NoteItemUML.from_xml( this, node );
		_items.append_val( item );
	}

}