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

public enum NoteItemType {
	MARKDOWN,
	CODE,
	IMAGE,
  UML,
	NUM;

	public string to_string() {
		switch( this ) {
			case MARKDOWN :  return( "markdown" );
			case CODE     :  return( "code" );
			case IMAGE    :  return( "image" );
      case UML      :  return( "uml" );
			default       :  assert_not_reached();
		}
	}

	public string label() {
		switch( this ) {
			case MARKDOWN :  return( _( "Markdown" ) );
			case CODE     :  return( _( "Code" ) );
			case IMAGE    :  return( _( "Image" ) );
      case UML      :  return( _( "UML Diagram" ) );
			default       :  assert_not_reached();
		}
	}

	public static NoteItemType parse( string str ) {
		switch( str ) {
			case "markdown" :  return( MARKDOWN );
			case "code"     :  return( CODE );
			case "image"    :  return( IMAGE );
      case "uml"      :  return( UML );
			default         :  return( NUM );
		}
	}

  public bool is_text() {
    return( (this == MARKDOWN) || (this == CODE) );
  }

  public bool spell_checkable() {
    return( this == MARKDOWN );
  }

	public NoteItem create( Note note ) {
		switch( this ) {
			case MARKDOWN :  return( new NoteItemMarkdown( note ) );
			case CODE     :  return( new NoteItemCode( note ) );
			case IMAGE    :  return( new NoteItemImage( note ) );
      case UML      :  return( new NoteItemUML( note ) );
			default       :  assert_not_reached();
		}
	}

  public ToolbarItem create_toolbar() {
    switch( this ) {
      case MARKDOWN :  return( new ToolbarMarkdown() );
      case CODE     :  return( new ToolbarCode() );
      case IMAGE    :  return( new ToolbarItem() );
      case UML      :  return( new ToolbarItem() );
      default       :  assert_not_reached();
    }
  }

	public void initialize_text( GtkSource.View text ) {
		switch( this ) {
			case MARKDOWN :  initialize_markdown_text( text );  break;
			case CODE     :  initialize_code_text( text );  break;
			case UML      :  initialize_uml_text( text );  break;
			default       :  break;
		}
	}

	private void initialize_markdown_text( GtkSource.View text ) {
		text.wrap_mode = Gtk.WrapMode.WORD;
	}

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

	private void initialize_uml_text( GtkSource.View text ) {
		text.wrap_mode = Gtk.WrapMode.NONE;
    text.auto_indent = true;
    text.indent_width = 3;
    text.insert_spaces_instead_of_tabs = true;
    text.smart_backspace = true;
    text.tab_width = 3;
    text.monospace = true;
	}

}

public class NoteItem {

  public static int current_id = 0;
  private const int max_image_width = 800;

  private string _content = "";

	public Note         note      { get; private set; }
	public int          id        { get; private set; }
  public NoteItemType item_type { get; private set; default = NoteItemType.MARKDOWN; }
  public bool         expanded  { get; set; default = true; }
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

	// Default constructor
	public NoteItem( Note note, NoteItemType type ) {
		this.id        = current_id++;
		this.note      = note;
    this.item_type = type;
	}

	// Constructor from XML input
	public NoteItem.from_xml( Xml.Node* node ) {
		load( node );
	}

  // Copy method (can be used to convert one item to another as well)
  public virtual void copy( NoteItem item ) {
  	this.note     = item.note;
    this._content = item._content;
    this.modified = item.modified;
  }

	// Used for string searching
	public virtual bool search( string str ) {
    return( content.contains( str ) );
	}

	// Returns the markdown text for this item
	public virtual string to_markdown( bool pandoc ) {
		return( "" );
	}

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

  // Returns the directory that contains the resource in the notebook associated with this note item's note.
  protected string get_resource_dir() {
    return( Path.build_filename( note.notebook.notebook_directory( note.notebook.id ), "resources" ) );
  }

	// Returns the filename of the resource file associated with this note item
  protected string get_resource_path( string extension ) {
  	return( Path.build_filename( get_resource_dir(), "resource-%d.%s".printf( id, extension ) ) );
  }

  // Returns the resource filename
  public virtual string get_resource_filename() {
    return( "" );
  }

  // Saves the given resource into the resource directory
  protected bool save_as_resource( File from_file, bool link ) {
    Utils.create_dir( get_resource_dir() );
    var to_file = File.new_for_path( get_resource_path( Utils.get_extension( from_file.get_path() ) ) );
    try {
      if( link && (from_file.get_uri_scheme() == "file") ) {
        return( to_file.make_symbolic_link( from_file.get_path() ) );
      } else {
        return( from_file.copy( to_file, FileCopyFlags.OVERWRITE ) );
      }
    } catch( Error e ) {
      stdout.printf( "ERROR: %s\n", e.message );
    }
    return( false );
  }

  // Deletes the resource associated with this note item
  public bool delete_resource() {
    var resource = get_resource_filename();
    if( FileUtils.test( resource, FileTest.EXISTS ) ) {
      if( FileUtils.test( resource, FileTest.IS_SYMLINK ) ) {
        try {
          string target_path = FileUtils.read_link( resource );
          return( FileUtils.unlink( resource ) == 0 );
        } catch( FileError e ) {
          stdout.printf( "ERROR:  %s\n", e.message );
          return( false );
        }
      } else {
        return( FileUtils.unlink( resource ) == 0 );
      }
    }
    return( false );
  }

	// Saves this note item
	public virtual Xml.Node* save() {
		Xml.Node* node = new Xml.Node( null, item_type.to_string() );
		node->set_prop( "id", id.to_string() );
    node->set_prop( "expanded", expanded.to_string() );
    node->add_content( content );
		modified = false;
		return( node );
	}

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