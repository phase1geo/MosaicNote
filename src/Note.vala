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

	private Notebook        _nb;
	private int             _id;
	private string          _title;
	private DateTime        _created;
	private DateTime        _changed;
	private bool            _locked;
	private Tags            _tags;
	private Array<NoteItem> _items;

	public bool modified { get; private set; default = false; }

	public string title {
		get {
			return( _title );
		}
		set {
			if( _title != value ) {
				_title = value;
				_changed = new DateTime.now_local();
				modified = true;
			}
		}
	}

	public DateTime created {
		get {
			return( _created );
		}
	}

	public DateTime changed {
		get {
			return( _changed );
		}
	}

	public bool locked {
		get {
      return( _locked );
		}
		set {
			if( _locked != value ) {
				_locked  = value;
				_changed = new DateTime.now_local();
        modified = true;
			}
		}
	}

	// Default constructor
	public Note( Notebook nb ) {
		_nb      = nb;
		_id      = current_id++;
		_title   = "";
		_created = new DateTime.now_local();
		_changed = new DateTime.now_local();
		_locked  = false;
		_tags    = new Tags();
    _items   = new Array<NoteItem>();
	}

	// Constructs note from XML node
	public Note.from_xml( Notebook nb, Xml.Node* node ) {
		_nb = nb;
		load( node );
	}

	public void add_note_item( uint pos, NoteItem item ) {
		_items.append_val( item );
	}

	public void delete_note_item( uint pos ) {
		_items.remove_index( pos );
		_modified = true;
	}

	// Returns the result of comparing our note to the given note
	public static int compare( Note a, Note b ) {
		return( (int)(a._id > b._id) - (int)(a._id < b._id) );
	}

	// Saves the note in XML format
	public Xml.Node* save() {

		if( modified ) {
			_changed = new DateTime.now_local();
			modified = false;
		}

		Xml.Node* node  = new Xml.Node( null, "note" );
		Xml.Node* items = new Xml.Node( null, "items" );

		node->set_prop( "id",      _id.to_string() );
		node->set_prop( "title",   _title );
		node->set_prop( "created", _created.format_iso8601() );
		node->set_prop( "changed", _changed.format_iso8601() );
		node->set_prop( "locked",  _locked.to_string() );

		node->append_child( _tags.save() );

		// Save the note items
		for( int i=0; i<_items.length; i++ ) {
			items->add_child( _items.index( i ).save() );
		}
		node->add_child( items );

		modified = true;

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
      _created = new DateTime.from_iso8601( c );
		}

		var m = node->get_prop( "changed" );
		if( m != null ) {
			_changed = new DateTime.from_iso8601( m );
		}

		for( Xml.Node* it=node->children; it!=null; it++ ) {
			if( it->type == Xml.ElementType.ELEMENT_NODE ) {
				switch( it->name ) {
					case "tags"  :  _tags.load( it );  break;
					case "items" :  load_items();  break;
				}
			}
		}

	}

	private void load_items( Xml.Node* node ) {
		for( Xml.Node* it=node->children; it!=null; it++ ) {
			if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
        	case "markdown" :  load_markdown_item( it );
        	case "code"     :  load_code_item( it );
        	case "image"    :  load_image_item( it );
        }
			}
		}
	}

	private void load_markdown_item( Xml.Node* node ) {
		var item = new ItemMarkdown.from_xml( node );
		items.append_val( item );
	}

	private void load_code_item( Xml.Node* node ) {
		var item = new ItemCode.from_xml( node );
		items.append_val( item );
	}

	private void load_image_item( Xml.Node* node ) {
		var item = new ItemImage.from_xml( node );
		items.append_val( item );
	}

}