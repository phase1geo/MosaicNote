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

  private string _content = "";

	public Note         note      { get; private set; }
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

	// Default constructor
	public NoteItem( Note note, NoteItemType type ) {
		this.note      = note;
    this.item_type = type;
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

	// Saves this note item
	public virtual Xml.Node* save() {
		Xml.Node* node = new Xml.Node( null, item_type.to_string() );
    node->add_content( content );
		modified = false;
		return( node );
	}

  // Loads the content from XML format
  protected virtual void load( Xml.Node* node ) {
    content = node->get_content();
  }


}