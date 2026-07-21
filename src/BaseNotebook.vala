/*
* Copyright (c) 2024-2026 (https://github.com/phase1geo/MosaicNote)
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

public class BaseNotebook : Object {

  protected string _name     = "";
  private   bool   _modified = false;

  public signal void changed();

  public string name {
    get {
      return( _name );
    }
    set {
      if( _name != value ) {
        _name = value;
        _modified = true;
        changed();
      }
    }
  }

  public bool current { set; get; default = false; }

  //-------------------------------------------------------------
  // Default constructor
  public BaseNotebook( string name ) {
    _name = name;
  }

  //-------------------------------------------------------------
  // Returns the number of stored notes
  public virtual int count() {
    return( 0 );
  }

  public virtual ListModel? get_model() {
    return( null );
  }

  //-------------------------------------------------------------
  // Saves the contents of the notebook to XML formatted file
  protected void base_save( Xml.Node* node ) {
    node->set_prop( "name", _name );
    _modified = false;
  }

  //-------------------------------------------------------------
  // Loads the contents of this notebook from XML format
  protected void base_load( Xml.Node* node ) {
    var n = node->get_prop( "name" );
    if( n != null ) {
      _name = n;
    }
  }

  //-------------------------------------------------------------
  // Returns the string version of this notebook for debugging
  // purposes.
  public virtual string to_string( string prefix = "" ) {
    return( "name: %s, current: %s".printf( name, current.to_string() ) );
  }

}
