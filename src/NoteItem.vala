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

using Gee;

public enum NoteItemType {
	MARKDOWN,
	CODE,
	IMAGE,
  UML,
  MATH,
  TABLE,
  ASSETS,
	NUM;

  //-------------------------------------------------------------
  // Displays the NoteItemType as a string that is used for saving
  // this value to a file.
	public string to_string() {
		switch( this ) {
			case MARKDOWN :  return( "markdown" );
			case CODE     :  return( "code" );
			case IMAGE    :  return( "image" );
      case UML      :  return( "uml" );
      case MATH     :  return( "math" );
      case TABLE    :  return( "table" );
      case ASSETS   :  return( "assets" );
			default       :  assert_not_reached();
		}
	}

  //-------------------------------------------------------------
  // Displays the NoteItemType as a translated string that is used
  // for matching user input values for search.
  public string search_string() {
    switch( this ) {
      case MARKDOWN :  return( _( "markdown" ) );
      case CODE     :  return( _( "code" ) );
      case IMAGE    :  return( _( "image" ) );
      case UML      :  return( _( "uml" ) );
      case MATH     :  return( _( "math" ) );
      case TABLE    :  return( _( "table" ) );
      case ASSETS   :  return( _( "assets" ) );
      default       :  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Displays the NoteItemType as a translated string that is
  // used for display within the application.
	public string label() {
		switch( this ) {
			case MARKDOWN :  return( _( "Markdown" ) );
			case CODE     :  return( _( "Code" ) );
			case IMAGE    :  return( _( "Image" ) );
      case UML      :  return( _( "UML Diagram" ) );
      case MATH     :  return( _( "Math Formula" ) );
      case TABLE    :  return( _( "Table" ) );
      case ASSETS   :  return( _( "Files" ) );
			default       :  assert_not_reached();
		}
	}

  //-------------------------------------------------------------
  // Parses the string value (created from to_string()) and returns
  // the enumerated value.
	public static NoteItemType parse( string str ) {
		switch( str ) {
			case "markdown" :  return( MARKDOWN );
			case "code"     :  return( CODE );
			case "image"    :  return( IMAGE );
      case "uml"      :  return( UML );
      case "math"     :  return( MATH );
      case "table"    :  return( TABLE );
      case "assets"   :  return( ASSETS );
			default         :  return( NUM );
		}
	}

  //-------------------------------------------------------------
  // Parses the string value (created from search_string()) and
  // returns the enumerated value.
  public static NoteItemType parse_search( string str ) {
    var down = str.down();
    if( down == _( "markdown" ) ) {
      return( MARKDOWN );
    } else if( down == _( "code" ) ) {
      return( CODE );
    } else if( down == _( "image" ) ) {
      return( IMAGE );
    } else if( down == _( "uml" ) ) {
      return( UML );
    } else if( down == _( "table" ) ) {
      return( TABLE );
    } else if( down == _( "assets" ) ) {
      return( ASSETS );
    } else if( down == _( "math" ) ) {
      return( MATH );
    } else {
      return( NUM );
    }
  }

  //-------------------------------------------------------------
  // Returns true if the note item can make use of the NoteItem.create_text()
  // function call.
  public bool is_text() {
    return( (this == MARKDOWN) || (this == CODE) );
  }

  //-------------------------------------------------------------
  // Returns true if this note item should have spellchecking enabled
  // for it.
  public bool spell_checkable() {
    return( this == MARKDOWN );
  }

  //-------------------------------------------------------------
  // Creates a note item object for the given note.
	public NoteItem create( Note note ) {
		switch( this ) {
			case MARKDOWN :  return( new NoteItemMarkdown( note ) );
			case CODE     :  return( new NoteItemCode( note ) );
			case IMAGE    :  return( new NoteItemImage( note ) );
      case UML      :  return( new NoteItemUML( note ) );
      case MATH     :  return( new NoteItemMath( note ) );
      case TABLE    :  return( new NoteItemTable( note, 0, 0 ) );
      case ASSETS   :  return( new NoteItemAssets( note ) );
			default       :  assert_not_reached();
		}
	}

  //-------------------------------------------------------------
  // Returns the toolbar object to use for the note item.
  public ToolbarItem create_toolbar() {
    switch( this ) {
      case MARKDOWN :  return( new ToolbarMarkdown() );
      case CODE     :  return( new ToolbarCode() );
      case IMAGE    :  return( new ToolbarItem() );
      case UML      :  return( new ToolbarItem() );
      case MATH     :  return( new ToolbarItem() );
      case TABLE    :  return( new ToolbarItem() );
      case ASSETS   :  return( new ToolbarItem() );
      default       :  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Initializes the given text widget options based on the
  // note type.
	public void initialize_text( GtkSource.View text ) {
		switch( this ) {
			case MARKDOWN :  initialize_markdown_text( text );  break;
			case CODE     :  initialize_code_text( text );      break;
			case UML      :  initialize_uml_text( text );       break;
      case MATH     :  initialize_math_text( text );      break;
			default       :  break;
		}
	}

  //-------------------------------------------------------------
  // Initializes a text widget to be used for Markdown editing.
	private void initialize_markdown_text( GtkSource.View text ) {
		text.wrap_mode = Gtk.WrapMode.WORD;
	}

  //-------------------------------------------------------------
  // Initializes a text widget to be used for coding.
	private void initialize_code_text( GtkSource.View text ) {
		text.wrap_mode = Gtk.WrapMode.NONE;
    text.show_line_numbers = true;
    text.show_line_marks = true;
    text.auto_indent = true;
    text.indent_width = 3;
    text.insert_spaces_instead_of_tabs = true;
    text.smart_backspace = true;
    text.tab_width = 3;
    text.monospace = true;
	}

  //-------------------------------------------------------------
  // Initializes a text widget to be used for UML scripting.
	private void initialize_uml_text( GtkSource.View text ) {
		text.wrap_mode = Gtk.WrapMode.NONE;
    text.auto_indent = true;
    text.indent_width = 3;
    text.insert_spaces_instead_of_tabs = true;
    text.smart_backspace = true;
    text.tab_width = 3;
    text.monospace = true;
	}

  //-------------------------------------------------------------
  // Initializes a text widget to be used for Math scripting.
  private void initialize_math_text( GtkSource.View text ) {
    text.wrap_mode = Gtk.WrapMode.NONE;
    text.monospace = true;
  }

}

public class NoteItem : Object {

  public static int current_id = 0;
  public static int current_resource_id = 0;
  private const int max_image_width = 800;

  private string _content  = "";
  private bool   _expanded = true;

	public Note         note      { get; private set; }
	public int          id        { get; private set; }
  public NoteItemType item_type { get; private set; default = NoteItemType.MARKDOWN; }
	public bool         modified  { get; protected set; default = false; }

	public signal void changed();

  public string content {
    get {
      return( _content );
    }
    set {
      if( _content != value ) {
        _content = value;
        modified = true;
        changed();
      }
    }
  }

  public bool expanded {
    get {
      return( _expanded );
    }
    set {
      if( _expanded != value ) {
        _expanded = value;
        modified = true;
      }
    }
  }

  //-------------------------------------------------------------
	// Default constructor
	public NoteItem( Note note, NoteItemType type ) {
    Object();
		this.id        = current_id++;
		this.note      = note;
    this.item_type = type;
	}

  //-------------------------------------------------------------
	// Constructor from XML input
	public NoteItem.from_xml( Xml.Node* node ) {
    Object();
		load( node );
	}

  //-------------------------------------------------------------
  // Copy method (can be used to convert one item to another as well)
  public virtual void copy( NoteItem item ) {
  	this.note     = item.note;
    this._content = item._content;
    this.modified = item.modified;
  }

  //-------------------------------------------------------------
	// Used for string searching
	public virtual bool search( string str ) {
    return( content.contains( str ) );
	}

  //-------------------------------------------------------------
	// Returns the markdown text for this item
	public virtual string to_markdown( NotebookTree? notebooks, bool pandoc ) {
		return( "" );
	}

  //-------------------------------------------------------------
  // Returns the markdown text for this item converting any
  // file references to relative references and copy those
  // references assets to the "assets" directory.
  public virtual string export( NotebookTree? notebooks, string assets_dir ) {
    return( "" );
  }

  //-------------------------------------------------------------
  // Copies the given filename asset to the specified directory within
  // dirname.  This may be used by the export function.
  protected virtual string copy_asset( string assets_dir, string filename ) {
    if( FileUtils.test( filename, FileTest.EXISTS ) ) {
      var basename = Path.get_basename( filename );
      var asset    = Path.build_filename( assets_dir, Path.get_basename( filename ) );
      try {
        var from_file = File.new_for_uri( filename );
        var to_file   = File.new_for_path( asset );
        to_file.copy( from_file, FileCopyFlags.NONE );
        return( Path.build_filename( Path.get_basename( assets_dir ), basename ) );
      } catch( Error e ) {}
    } else {
      return( filename );
    }
    return( "" );
  }

  //-------------------------------------------------------------
	// If we are generating for pandoc, adjusts the given markdown image text
	// if the given image width exceeds the maximum allowed width.
	protected string format_for_width( string md, string image_file, bool pandoc ) {
		if( pandoc ) {
  	  var width = Utils.image_width( image_file );
  	  if( width > max_image_width ) {
  	  	return( md + "{ width=%dpx }".printf( max_image_width ) );
  	  }
  	}
		return( md );
	}

  //-------------------------------------------------------------
  // Returns the directory that contains the resource in the notebook associated with this note item's note.
  public string get_resource_dir() {
    return( Path.build_filename( note.notebook.notebook_directory( note.notebook.id ), "resources" ) );
  }

  //-------------------------------------------------------------
	// Returns the filename of the resource file associated with this note item
  protected string get_resource_path( string extension, int? extra_id = null ) {
    if( extra_id == null ) {
    	return( Path.build_filename( get_resource_dir(), "resource-%d.%s".printf( id, extension ) ) );
    } else {
      return( Path.build_filename( get_resource_dir(), "resource-%d-%d.%s".printf( id, extra_id, extension ) ) );
    }
  }

  //-------------------------------------------------------------
  // Returns the resource filename
  public virtual string get_resource_filename() {
    return( "" );
  }

  //-------------------------------------------------------------
  // Saves the given resource into the resource directory
  protected bool save_as_resource( File from_file, bool link, int? extra_id = null ) {
    Utils.create_dir( get_resource_dir() );
    var to_file = File.new_for_path( get_resource_path( Utils.get_extension( from_file.get_uri() ), extra_id ) );
    try {
      if( link && (from_file.get_uri_scheme() == "file") ) {
        FileUtils.remove( to_file.get_path() );
        return( to_file.make_symbolic_link( from_file.get_path() ) );
      } else {
        return( from_file.copy( to_file, FileCopyFlags.OVERWRITE ) );
      }
    } catch( Error e ) {
      stdout.printf( "ERROR: %s\n", e.message );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Deletes the resource associated with this note item
  public bool delete_resource() {
    var resource = get_resource_filename();
    if( FileUtils.test( resource, FileTest.EXISTS ) ) {
      if( FileUtils.test( resource, FileTest.IS_SYMLINK ) ) {
        return( FileUtils.unlink( resource ) == 0 );
      } else {
        return( FileUtils.unlink( resource ) == 0 );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Adds any note links stored in the note item.
  public virtual void get_note_links( HashSet<string> note_titles ) {}

  //-------------------------------------------------------------
	// Saves this note item
	public virtual Xml.Node* save() {
		Xml.Node* node = new Xml.Node( null, item_type.to_string() );
		node->set_prop( "id", id.to_string() );
    node->set_prop( "expanded", expanded.to_string() );
    node->add_content( content );
		modified = false;
		return( node );
	}

  //-------------------------------------------------------------
  // Loads the content from XML format
  protected virtual void load( Xml.Node* node ) {
  	var i = node->get_prop( "id" );
  	if( i != null ) {
  		id = int.parse( i );
  	} else {
  		id = current_id++;
  	}
    var e = node->get_prop( "expanded" );
    if( e != null ) {
      expanded = bool.parse( e );
    }
    _content = node->get_content();
  }

}