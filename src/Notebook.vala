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

public class Notebook : Object {

	public static int current_id = 0;

	private string      _name;
	private Array<Note> _notes;
	private bool        _modified = false;

	public string name {
		get {
			return( _name );
		}
		set {
			if( _name != value ) {
				_name = value;
				_modified = true;
			}
		}
	}

	// Default constructor
	public Notebook( string name ) {
		_name  = name;
		_id    = current_id++;
	  _notes = new Array<Note>();	
	}

	// Construct from XML file
	public Notebook.from_xml( int id ) {
		load( id );
	}

	// Returns true if the given ID matches our own
	public bool matches( int id ) {
		return( _id == id );
	}

	// Adds the given note to the notebook
  public void add_note( Note note ) {
  	_notes.append_val( note );
  }	

  // Searches for and deletes the note (if found) in the notebook
  public void delete_note( Note note ) {
  	uint pos;
  	if( _notes.binary_search( note, Note.compare, out pos ) ) {
    	_notes.remove_index( pos );
    }
  }

  // Returns true if anything has been modified by the user in this notebook
  public bool is_modified() {
  	if( !_modified ) {
      for( int i=0; i<_notes.length; i++ ) {
      	if( _notes.modified ) {
      		return( true );
      	}
      }
      return( false );
  	}
  	return( true );
  }

  // Name of Notebook XML file
  private string xml_file() {
    return( Utils.user_location( GLib.Path.build_filename( "notebook-%d".printf( id ), "notebook.xml" ) ) );
  }

  // Saves the contents of the notebook to XML formatted file
	public void save() {

	  Xml.Doc*  doc  = new Xml.Doc( "1.0" );
	  Xml.Node* root = new Xml.Node( null, "notebook" );

	  root->set_prop( "version", MosaicNote.version );
	  root->set_prop( "name", _name );
	  root->set_prop( "id",   _id );

	  for( uint i=0; i<_notes.length; i++ ) {
	  	var note = _notes.index( i );
	  	root->add_child( note.save() );
	  } 
	
	  doc->set_root_element( root );
	  doc->save_format_file( xml_file(), 1 );
	
	  delete doc;

	  _modified = false;

  }

  // Loads the contents of this notebook from XML format
  private void load() {

    var doc = Xml.Parser.read_file( xml_file(), null, (Xml.ParserOption.HUGE | Xml.ParserOption.NOWARNING) );
    if( doc == null ) {
      return;
    }

    Xml.Node* root = doc->get_root_element();
    
    var verson = root->get_prop( "version" );
    if( verson != null ) {
      check_version( verson );
    }

    var n = node->get_prop( "name" );
    if( n != null ) {
    	_name = n;
    }

    var i = node->get_prop( "id" );
    if( i != null ) {
    	_id = int.parse( i );
    }
  
    for( Xml.Node* it = root->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "note") ) {
      	var note = new Note.from_xml( it );
      	_notes.append_val( note );
      }
    }
    
    delete doc;

  }

}