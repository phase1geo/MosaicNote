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

public class NoteItemImage : NoteItem {

	private string _uri = "";
	private string _description = "";

	public string uri {
	  get {
	  	return( _uri );
	  }
	  set {
	  	if( _uri != value ) {
        var file = File.new_for_uri( value );
        if( save_as_resource( file, true ) ) {
          _uri     = value;
          modified = true;
          changed();
        }
	  	}
	  }
	}

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
	public NoteItemImage( Note note ) {
		base( note, NoteItemType.IMAGE );
	}

  //-------------------------------------------------------------
	// Constructor from XML format
	public NoteItemImage.from_xml( Note note, Xml.Node* node ) {
		base( note, NoteItemType.IMAGE );
		load( node );
	}

  //-------------------------------------------------------------
	// Copies the given note item to ourselves
  public override void copy( NoteItem item ) {
    base.copy( item );
    var image = (item as NoteItemImage);
    if( image != null ) {
      this.uri = image.uri;
    } else if( Utils.is_url( item.content ) ) {
    	this.uri = item.content;
    	this.content = "";
    }
  }

  //-------------------------------------------------------------
  // Searches the image description for the given search pattern.
  public override bool search( string pattern ) {
    return( _description.contains( pattern ) );
  }

  //-------------------------------------------------------------
  // Returns the Markdown code for this item
  public override string to_markdown( NotebookTree? notebooks, bool pandoc ) {
  	var file = File.new_for_uri( uri );
	  return( format_for_width( "![%s](%s)".printf( description, uri ), file.get_path(), pandoc ) );
  }

  //-------------------------------------------------------------
  // Returns the Markdown code for this item and copies the asset
  // to the specified assets directory.
  public override string export( NotebookTree? notebooks, string assets_dir ) {
    var asset = copy_asset( assets_dir, get_resource_filename() );
  	return( "![%s](%s)".printf( description, asset ) );
  }

  //-------------------------------------------------------------
  // Returns the resource filename
  public override string get_resource_filename() {
    return( get_resource_path( Utils.get_extension( uri ) ) );
  }

  //-------------------------------------------------------------
	// Saves the content in XML format
	public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "uri", uri );
    node->set_prop( "description", description );
    return( node );
	}

  //-------------------------------------------------------------
	// Loads the content from XML format
	protected override void load( Xml.Node* node ) {
    base.load( node );
		var u = node->get_prop( "uri" );
		if( u != null ) {
			_uri = u;
		}
		var d = node->get_prop( "description" );
		if( d != null ) {
			_description = d;
		}
	}

}