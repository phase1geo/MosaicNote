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

public class Notebook : BaseNotebook {

	public static int current_id = 0;

	private int         _id;
	private Array<Note> _notes;
	private bool        _modified = false;

	public int id {
		get {
			return( _id );
		}
	}

	// Default constructor
	public Notebook( string name ) {
    base( name );
		_id    = current_id++;
	  _notes = new Array<Note>();	
	}

	// Construct from XML file
	public Notebook.from_xml( int id ) {
    base( "" );
		_notes = new Array<Note>();
		load( id );
	}

	// Number of stores notes
	public override int count() {
		return( (int)_notes.length );
	}

	// Returns the note at the given position
	public Note get_note( int pos ) {
		return( _notes.index( pos ) );
	}

  // Returns the model containing the list of stored notes
  public override ListModel? get_model() {

    var list = new ListStore( typeof(Note) );

    for( int i=0; i<_notes.length; i++ ) {
      list.append( _notes.index( i ) );
    }

    return( list );

  }

	// Returns true if the given ID matches our own
	public bool matches( int id ) {
		return( _id == id );
	}

	// Adds the given note to the notebook
  public void add_note( Note note ) {
  	_notes.append_val( note );
  	_modified = true;
  	changed();
  }	

  // Searches for and deletes the note (if found) in the notebook
  public void delete_note( Note note ) {
  	uint pos;
  	if( _notes.binary_search( note, Note.compare, out pos ) ) {
    	_notes.remove_index( pos );
    	_modified = true;
    	changed();
    }
  }

  // Searches the list of notes for one that matches the given ID.  If it is found, return it; otherwise, return null.
  public Note? find_note( int id ) {
  	for( int i=0; i<_notes.length; i++ ) {
  		if( _notes.index( i ).id == id ) {
  			return( _notes.index( i ) );
  		}
  	}
  	return( null );
  }

  // Searches for notes that contain the given tag and appends them to the given notes list.
  public void get_notes_with_tag( string tag, Array<Note> notes ) {
  	for( int i=0; i<_notes.length; i++ ) {
  		if( _notes.index( i ).contains_tag( tag ) ) {
  			notes.append_val( _notes.index( i ) );
  		}
  	}
  }

  //-------------------------------------------------------------
  // Populates the given smart notebook with the notes that match
  // the smart criteria.
  public void populate_smart_notebook( SmartNotebook notebook ) {
    for( int i=0; i<_notes.length; i++ ) {
      notebook.handle_note( _notes.index( i ) );
    }
  }

  // Returns true if anything has been modified by the user in this notebook
  public bool is_modified() {
  	if( !_modified ) {
      for( int i=0; i<_notes.length; i++ ) {
      	if( _notes.index( i ).modified ) {
      		return( true );
      	}
      }
      return( false );
  	}
  	return( true );
  }

  public string notebook_directory( int id ) {
  	return( Utils.user_location( GLib.Path.build_filename( "notebooks", "notebook-%d".printf( id ) ) ) );
  }

  // Name of Notebook XML file
  private string xml_file( int id ) {
    return( GLib.Path.build_filename( notebook_directory( id ), "notebook.xml" ) );
  }

  // Saves the contents of the notebook to XML formatted file
	public void save() {

		// Make sure that the notebook directory exists
		Utils.create_dir( notebook_directory( _id ) );

	  Xml.Doc*  doc  = new Xml.Doc( "1.0" );
	  Xml.Node* root = new Xml.Node( null, "notebook" );

	  root->set_prop( "version", MosaicNote.current_version );
	  root->set_prop( "id",   _id.to_string() );

    base_save( root );

	  for( uint i=0; i<_notes.length; i++ ) {
	  	var note = _notes.index( i );
	  	root->add_child( note.save() );
	  } 
	
	  doc->set_root_element( root );
	  doc->save_format_file( xml_file( _id ), 1 );
	
	  delete doc;

	  _modified = false;

  }

  // Loads the contents of this notebook from XML format
  private void load( int id ) {

    var doc = Xml.Parser.read_file( xml_file( id ), null, (Xml.ParserOption.HUGE | Xml.ParserOption.NOWARNING) );
    if( doc == null ) {
      return;
    }

    Xml.Node* root = doc->get_root_element();
    
    var verson = root->get_prop( "version" );
    if( verson != null ) {
      check_version( verson );
    }

    var i = root->get_prop( "id" );
    if( i != null ) {
    	_id = int.parse( i );
    }

    base_load( root );
  
    for( Xml.Node* it = root->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "note") ) {
      	var note = new Note.from_xml( this, it );
      	_notes.append_val( note );
      }
    }
    
    delete doc;

  }

  private void check_version( string version ) {

  	// Nothing to do here yet

  }

}