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

public class NoteItemMath : NoteItem {

  private string _description = "";

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
	public NoteItemMath( Note note ) {
		base( note, NoteItemType.MATH );
	}

  //-------------------------------------------------------------
	// Constructor from XML node
	public NoteItemMath.from_xml( Note note, Xml.Node* node ) {
		base( note, NoteItemType.MATH );
		load( node );
	}

  //-------------------------------------------------------------
  // Searches the description and math expression for the given
  // search string.
  public override bool search( string pattern ) {
    return( description.contains( pattern ) || base.search( pattern ) );
  }

  //-------------------------------------------------------------
	// Converts the content to markdown text
	public override string to_markdown( NotebookTree? notebooks, bool pandoc ) {
    if( (content != "") && FileUtils.test( get_resource_filename(), FileTest.EXISTS ) ) {
  		return( "![%s](file://%s)".printf( _description, get_resource_filename() ) );
    }
    return( "" );
	}

  //-------------------------------------------------------------
  // Exports the math formula image to the assets directory and returns
  // the markdown string.
  public override string export( NotebookTree? notebooks, string assets_dir ) {
    if( (content != "") && FileUtils.test( get_resource_filename(), FileTest.EXISTS ) ) {
      var asset = copy_asset( assets_dir, get_resource_filename() );
      return( "![%s](%s)".printf( _description, asset ) );
    }
    return( "" );
  }

  //-------------------------------------------------------------
  // Returns the pathname to the resource containing the mathmatical
  // image.
  public override string get_resource_filename() {
    return( get_resource_path( "png" ) );
  }

  //-------------------------------------------------------------
  // Saves the content in XML format
  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "description", description );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads the content from XML format
  protected override void load( Xml.Node* node ) {
    base.load( node );
    var d = node->get_prop( "description" );
    if( d != null ) {
      _description = d;
    }
  }
}