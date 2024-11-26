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

	private int       _id;
  private ListStore _notes;
	private bool      _modified = false;

	public int id {
		get {
			return( _id );
		}
	}

  //-------------------------------------------------------------
	// Default constructor
	public Notebook( string name ) {
    base( name );
		_id    = current_id++;
    _notes = new ListStore( typeof( Note ) );
	}

  //-------------------------------------------------------------
	// Construct from XML file
	public Notebook.from_xml( int id, string? build_name = null ) {
    base( "" );
    _notes = new ListStore( typeof( Note ) );
		load( id, build_name );
	}

  //-------------------------------------------------------------
  // Returns the model containing the list of notes
  public override ListModel? get_model() {
    return( _notes );
  }

  //-------------------------------------------------------------
	// Number of stores notes
	public override int count() {
		return( (int)_notes.get_n_items() );
	}

  //-------------------------------------------------------------
	// Returns the note at the given position
	public Note get_note( int pos ) {
		return( (Note)_notes.get_item( pos ) );
	}

  //-------------------------------------------------------------
	// Returns true if the given ID matches our own
	public bool matches( int id ) {
		return( _id == id );
	}

  //-------------------------------------------------------------
	// Adds the given note to the notebook
  public void add_note( Note note ) {
  	_notes.append( note );
  	_modified = true;
  	changed();
  }	

  //-------------------------------------------------------------
  // Moves all of the notes from the given notebook into this
  // notebook.
  public void add_notebook( Notebook nb ) {
    if( nb.count() > 0 ) {
      for( int i=0; i<nb.count(); i++ ) {
        var note = nb.get_note( i );
        _notes.append( note );
      }
      _modified = true;
      changed();
    }
  }

  //-------------------------------------------------------------
  // Searches for and deletes the note (if found) in the notebook
  public void delete_note( Note note ) {
    for( int i=0; i<count(); i++ ) {
      if( get_note( i ) == note ) {
        _notes.remove( i );
        _modified = true;
        changed();
        break;
      }
    }
  }

  //-------------------------------------------------------------
  // Deletes all notes in the notebook.  This is only used for the
  // special trash notebook.
  public void delete_all_notes() {
    if( count() > 0 ) {
      _notes.remove_all();
      _modified = true;
      changed();
    }
  }

  //-------------------------------------------------------------
  // Copies the given note to this notebook.
  public void copy_note( Note note ) {
    var new_note = new Note.copy( this, note );
    _notes.append( new_note );
    _modified = true;
    changed();
  }

  //-------------------------------------------------------------
  // Moves the specified note to this notebook from its previous
  // notebook.
  public void move_note( Note note ) {
    _notes.append( note );
    note.notebook.delete_note( note );
    note.notebook = this;
    _modified = true;
    changed();
  }

  //-------------------------------------------------------------
  // Searches the list of notes for one that matches the given ID.
  // If it is found, return it; otherwise, return null.
  public Note? find_note_by_id( int id ) {
  	for( int i=0; i<count(); i++ ) {
      var note = get_note( i );
  		if( note.id == id ) {
  			return( note );
  		}
  	}
  	return( null );
  }

  //-------------------------------------------------------------
  // Searches the list of notes for one that contains a note item
  // that matches the given ID.  If it is found, return it;
  // otherwise, return null.
  public NoteItem? find_note_item( int id ) {
    for( int i=0; i<count(); i++ ) {
      var note = get_note( i );
      for( int j=0; j<note.size(); j++ ) {
        var item = note.get_item( j );
        if( item.id == id ) {
          return( item );
        }
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Searches the list of notes for one that matches the given title.
  // If it is found, return it; otherwise, return null.
  public Note? find_note_by_title( string title ) {
    for( int i=0; i<count(); i++ ) {
      var note = get_note( i );
      if( note.title == title ) {
        return( note );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Searches for notes that contain the given tag and appends them to the given notes list.
  public void get_notes_with_tag( string tag, Array<Note> notes ) {
  	for( int i=0; i<count(); i++ ) {
      var note = get_note( i );
  		if( note.contains_tag( tag ) ) {
  			notes.append_val( note );
  		}
  	}
  }

  //-------------------------------------------------------------
  // Populates the given smart notebook with the notes that match
  // the smart criteria.
  public void populate_smart_notebook( SmartNotebook notebook ) {
    for( int i=0; i<count(); i++ ) {
      notebook.handle_note( get_note( i ) );
    }
  }

  //-------------------------------------------------------------
  // Returns true if anything has been modified by the user in this notebook
  public bool is_modified() {
  	if( !_modified ) {
      for( int i=0; i<count(); i++ ) {
      	if( get_note( i ).modified ) {
      		return( true );
      	}
      }
      return( false );
  	}
  	return( true );
  }

  //-------------------------------------------------------------
  // Removes the current notebook from the filesystem.
  public void remove_notebook() {
    DirUtils.remove( notebook_directory( _id ) );
  }

  //-------------------------------------------------------------
  // Outputs all notes within the notebook as a Markdown string.
  public string to_markdown( NotebookTree notebooks, bool pandoc ) {
    var str = "---\ntitle: '%s'\n---\n\n".printf( name );
    for( int i=0; i<count(); i++ ) {
      str += get_note( i ).to_markdown( notebooks, false, pandoc ) + "\n\n---\n\n";
    }
    return( str );
  }

  //-------------------------------------------------------------
  // Exports this notebook in the given directory.
  public void export( NotebookTree notebooks, string root_dir ) {
    var dirname    = Path.build_filename( root_dir, name );
    var assets_dir = Path.build_filename( dirname, "assets" );
    if( Utils.create_dir( dirname ) && Utils.create_dir( assets_dir ) ) {
      try {
        for( int i=0; i<count(); i++ ) {
          get_note( i ).export( notebooks, dirname, assets_dir );
        }
      } catch( FileError e ) {}
    }
  }

  //-------------------------------------------------------------
  // Returns the directory where this notebook will be saved on disk.
  public string notebook_directory( int id ) {
  	return( Utils.user_location( GLib.Path.build_filename( "notebooks", "notebook-%d".printf( id ) ) ) );
  }

  //-------------------------------------------------------------
  // Name of Notebook XML file
  private string xml_file( int id ) {
    return( GLib.Path.build_filename( notebook_directory( id ), "notebook.xml" ) );
  }

  //-------------------------------------------------------------
  // Saves the contents of the notebook to XML formatted file
	public void save() {

		// Make sure that the notebook directory exists
		Utils.create_dir( notebook_directory( _id ) );

	  Xml.Doc*  doc  = new Xml.Doc( "1.0" );
	  Xml.Node* root = new Xml.Node( null, "notebook" );

	  root->set_prop( "version", MosaicNote.current_version );
	  root->set_prop( "id",   _id.to_string() );

    base_save( root );

	  for( int i=0; i<count(); i++ ) {
	  	var note = get_note( i );
	  	root->add_child( note.save() );
	  } 
	
	  doc->set_root_element( root );
	  doc->save_format_file( xml_file( _id ), 1 );
	
	  delete doc;

	  _modified = false;

  }

  //-------------------------------------------------------------
  // Loads the contents of this notebook from XML format
  private void load( int id, string? build_name ) {

    var doc = Xml.Parser.read_file( xml_file( id ), null, (Xml.ParserOption.HUGE | Xml.ParserOption.NOWARNING) );
    if( doc == null ) {
      if( build_name != null ) {
        _id = current_id++;
        name = build_name;
      }
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
      	_notes.append( note );
      }
    }
    
    delete doc;

  }

  //-------------------------------------------------------------
  // Checks the current version and if it requires some sort of
  // update, this function will make the change.
  private void check_version( string version ) {

  	// Nothing to do here yet

  }

}
