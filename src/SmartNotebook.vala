/*
* Copyright (c) 2024 (https://github.com/phase1geo/MosaicNote)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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

public enum SmartNotebookType {
  USER,
  BUILTIN,
  TAG,
  TRASH,
  NUM;

  public string to_string() {
    switch( this ) {
      case USER    :  return( "user" );
      case BUILTIN :  return( "builtin" );
      case TAG     :  return( "tag" );
      case TRASH   :  return( "trash" );
      default      :  assert_not_reached();
    }
  }

  public static SmartNotebookType parse( string val ) {
    switch( val ) {
      case "user"    :  return( USER );
      case "builtin" :  return( BUILTIN );
      case "tag"     :  return( TAG );
      case "trash"   :  return( TRASH );
      default        :  assert_not_reached();
    }
  }

}

public class SmartNotebook : BaseNotebook {

  private SmartLogicFilter   _filter;
  private Gee.HashSet<int>   _notes;
  private bool               _modified = false;
  private SmartNotebookType  _type     = SmartNotebookType.USER;
  private NotebookTree       _notebooks;

  public SmartNotebookType notebook_type {
    get {
      return( _type );
    }
  }

  public SmartLogicFilter filter {
    get {
      return( _filter );
    }
    set {
      _filter = value;
    }
  }

  //-------------------------------------------------------------
  // Default constructor
  public SmartNotebook( string name, SmartNotebookType type, NotebookTree notebooks ) {
    base( name );
    _filter    = new FilterAnd();
    _notes     = new Gee.HashSet<int>();
    _type      = type;
    _notebooks = notebooks;
  }

  //-------------------------------------------------------------
  // Constructor from XML data
  public SmartNotebook.from_xml( Xml.Node* node, NotebookTree notebooks ) {
    base( "" );
    _filter    = new FilterAnd();
    _notes     = new Gee.HashSet<int>();
    _notebooks = notebooks;

    load( node );
  }

  //-------------------------------------------------------------
  // Returns the number of matched notes
  public override int count() {
    return( _notes.size );
  }

  //-------------------------------------------------------------
  // Returns the model containing the list of stored notes.
  public override ListModel? get_model() {

    var list = new ListStore( typeof(Note) );

    _notes.foreach((id) => {
      list.append( _notebooks.find_note( id ) );
      return( true );
    });

    return( list );

  }

  //-------------------------------------------------------------
  // Returns the number of stored filters
  public int filter_size() {
    return( _filter.size() );
  }

  //-------------------------------------------------------------
  // Returns the filter at the given index location
  public SmartFilter filter_get( int index ) {
    return( _filter.get_filter( index ) );
  }

  //-------------------------------------------------------------
  // Adds the given smart filter to the list of filters
  public void add_filter( SmartFilter filter ) {
    _filter.add_filter( filter );
  }

  //-------------------------------------------------------------
  // Removes the filter at the given index
  public void remove_filter( int index ) {
    _filter.remove_filter( index );
  }

  //-------------------------------------------------------------
  // Checks the given note to see if this notebook should
  // add support for this note
  public bool handle_note( Note note ) {

    stdout.printf( "CHECKING NOTE: %s\n", note.title );

    // Check to see if the note passes all of the stored filters
    if( _filter.check_note( note ) ) {

      stdout.printf( "  ADDING NOTE\n" );

      var modified = _notes.add( note.id );
      _modified |= modified;
      return( modified );

    } else {

      stdout.printf( "  REMOVING NOTE\n" );

      var modified = _notes.remove( note.id );
      _modified |= modified;
      return( modified );

    }

  }

  //-------------------------------------------------------------
  // Saves the smartbook in XML format
  public Xml.Node* save() {

    Xml.Node* node = new Xml.Node( null, "smart-notebook" );
    string[]  ids  = {};

    // Convert the stored note IDs as a comma-separated string
    _notes.foreach((id) => {
      ids += id.to_string();
      return( true );
    });

    node->set_prop( "name", name );
    node->set_prop( "type", _type.to_string() );
    node->set_prop( "ids", string.joinv( ",", ids ) );

    node->add_child( _filter.save() );

    _modified = false;

    return( node );

  }

  //-------------------------------------------------------------
  // Loads the contents of this smart folder from XML format
  public void load( Xml.Node* node ) {

    var n = node->get_prop( "name" );
    if( n != null ) {
      name = n;
    }

    var t = node->get_prop( "type" );
    if( t != null ) {
      _type = SmartNotebookType.parse( t );
    }

    var i = node->get_prop( "ids" );
    if( i != null ) {
      var ids = i.split( "," );
      foreach( var id in ids ) {
        _notes.add( int.parse( id ) );
      }
    }

    for( Xml.Node* it = node->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "filter-and") ) {
        _filter.load( it );
      }
    }

  }

}