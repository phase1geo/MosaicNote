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

public class NoteItem {

  private string _content = "";

	public string name     { get; private set; default = ""; }
	public string label    { get; private set; default = ""; }
	public bool   modified { get; protected set; default = false; }

  public string content {
    get {
      return( _content );
    }
    set {
      if( _content != value ) {
        _content = value;
        modified = true;
      }
    }
  }

	// Default constructor
	public NoteItem( string name, string label ) {
    this.name  = name;
    this.label = label;
	}

  // Copy method (can be used to convert one item to another as well)
  public virtual void copy( NoteItem item ) {
    this._content = item._content;
    this.modified = item.modified;
  }

	// Used for string searching
	public virtual bool search( string str ) {
    return( content.contains( str ) );
	}

	// Saves this note item
	public virtual Xml.Node* save() {
		Xml.Node* node = new Xml.Node( null, name );
    node->add_content( content );
		modified = false;
		return( node );
	}

  // Loads the content from XML format
  protected virtual void load( Xml.Node* node ) {
    content = node->get_content();
  }


}