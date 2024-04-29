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

public class Favorites {

	private ListStore _model;
	private bool      _modified = false;

	public ListStore model {
		get {
			return( _model );
		}
	}

	// Default constructor
	public Favorites() {
		_model = new ListStore( Type.OBJECT );
	}

	// Favorites the given notebook
	public void favorite_notebook( Notebook nb ) {
		var fav = new Favorite( true, nb.id );
		_model.insert( 0, fav );
	}

	// Favorites the given note
	public void favorite_note( Note note ) {
		var fav = new Favorite( false, note.id );
		_model.insert( 0, fav );
	}

	// Removes the given favorite from the favorite list
	public void unfavorite( Favorite fav ) {
		uint pos;
		if( _model.find( fav, out pos ) ) {
			_model.remove( pos );
		}
	}

	// Returns the pathname of the XML file
  private string xml_file() {
    return( Utils.user_location( "favorites.xml" ) );
  }

  // Saves the current state of this list of favorites
	public void save() {

	  Xml.Doc*  doc  = new Xml.Doc( "1.0" );
	  Xml.Node* root = new Xml.Node( null, "favorites" );

	  root->set_prop( "version", MosaicNote.version );

	  for( uint i=0; i<_model.get_n_items(); i++ ) {
	  	var fav = (Favorite)_model.get_object( i );
	  	root->add_child( fav.save() );
	  } 
	
	  doc->set_root_element( root );
	  doc->save_format_file( xml_file(), 1 );
	
	  delete doc;

	}

	// Loads the contents of this
	public void load() {

    var doc = Xml.Parser.read_file( xml_file(), null, (Xml.ParserOption.HUGE | Xml.ParserOption.NOWARNING) );
    if( doc == null ) {
      return;
    }

    Xml.Node* root = doc->get_root_element();
    
    var verson = root->get_prop( "version" );
    if( verson != null ) {
      check_version( verson );
    }
  
    for( Xml.Node* it = root->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "favorite") ) {
      	var fav = new Favorite.from_xml( it );
      	_model.append( fav );
      }
    }
    
    delete doc;

	}

	// Checks the stored version against the current version of the application.  If changes have been
	// made to the format, handle them here.
	private void check_version( string version ) {

		// Nothing to do yet

	}

}