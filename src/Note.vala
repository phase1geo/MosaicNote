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

public class Note : Object {

  public static int current_id = 0;

  private Notebook           _nb;        // done
  private int                _id;
  private string             _title;
  private DateTime           _created;   // done
  private DateTime           _updated;   // done
  private DateTime           _viewed;    // done
  private bool               _locked;
  private bool               _favorite;  // done
  private Tags               _tags;      // done
  private Array<NoteItemRow> _rows;
  private HashSet<int>       _referred;

  public bool modified { get; private set; default = false; }

  public Notebook notebook {
    get {
      return( _nb );
    }
    set {
      _nb = value;
    }
  }

  public int id {
    get {
      return( _id );
    }
  }

  public string title {
    get {
      return( _title );
    }
    set {
      if( _title != value ) {
        _title = value;
        modified = true;
        title_changed();
      }
    }
  }

  public DateTime created {
    get {
      return( _created );
    }
  }

  public DateTime updated {
    get {
      return( _updated );
    }
  }

  public DateTime viewed {
    get {
      return( _viewed );
    }
  }

  public bool locked {
    get {
      return( _locked );
    }
    set {
      if( _locked != value ) {
        _locked  = value;
        modified = true;
      }
    }
  }

  public bool favorite {
    get {
      return( _favorite );
    }
    set {
      if( _favorite != value ) {
        _favorite = value;
        modified  = true;
      }
    }
  }

  public Tags tags {
    get {
      return( _tags );
    }
  }

  public HashSet<int> referred {
    get {
      return( _referred );
    }
  }

  public signal void changed();
  public signal void title_changed();

  //-------------------------------------------------------------
  // Default constructor
  public Note( Notebook nb, bool add_initial_item = true ) {

    _nb       = nb;
    _id       = current_id++;
    _title    = "";
    _created  = new DateTime.now_local();
    _updated  = new DateTime.now_local();
    _viewed   = new DateTime.now_local();
    _locked   = false;
    _favorite = false;
    _tags     = new Tags();
    _rows     = new Array<NoteItemRow>();
    _referred = new HashSet<int>();

    if( add_initial_item ) {
      var row  = new NoteItemRow( this );
      var item = new NoteItemMarkdown( row );
      row.add_item( item );
      _rows.append_val( row );
    }

  }

  //-------------------------------------------------------------
  // Constructs note from XML node
  public Note.from_xml( Notebook nb, Xml.Node* node ) {
    _nb       = nb;
    _tags     = new Tags();
    _rows     = new Array<NoteItemRow>();
    _referred = new HashSet<int>();

    load( node );
  }

  //-------------------------------------------------------------
  // Copies the given note to this note and sets the notebook
  // to the specified notebook.
  public Note.copy( Notebook nb, Note note ) {

    _nb       = nb;
    _id       = current_id++;
    _title    = note.title;
    _created  = new DateTime.now_local();
    _updated  = new DateTime.now_local();
    _viewed   = new DateTime.now_local();
    _locked   = note.locked;
    _favorite = note.favorite;
    _tags     = new Tags();
    _rows     = new Array<NoteItemRow>();
    _referred = new HashSet<int>();

    _tags.copy( note.tags );

    for( int i=0; i<note._rows.length; i++ ) {
      var new_row = new NoteItemRow.copy( note._rows.index( i ) );
      _rows.append_val( new_row );
    }

  }

  //-------------------------------------------------------------
  // Sets the title, but does not change the status of the modified
  // indicator.
  public void initialize_title( string init_title ) {
    _title = init_title;
  }

  //-------------------------------------------------------------
  // Sets the creation date to the given value, but does not change
  // the status of the modified indicator.
  public void initialize_created( DateTime? dt ) {
    if( dt != null ) {
      _created = dt;
    }
  }

  //-------------------------------------------------------------
  // Sets the creation date to the given value, but does not change
  // the status of the modified indicator.
  public void initialize_updated( DateTime? dt ) {
    if( dt != null ) {
      _updated = dt;
    }
  }

  //-------------------------------------------------------------
  // Updates the viewed timestamp
  public void reviewed() {
    _viewed = new DateTime.now_local();
  }

  //-------------------------------------------------------------
  // Returns the number of note items in the array
  public int rows() {
    return( (int)_rows.length );
  }

  //-------------------------------------------------------------
  // Returns the note item at the given index
  public NoteItemRow get_row( int index ) {
    return( _rows.index( index ) );
  }

  //-------------------------------------------------------------
  // Returns the item located at the specified row/column.
  public NoteItem get_item( int row, int col ) {
    var note_row = _rows.index( row );
    return( note_row.get_item( col ) );
  }

  //-------------------------------------------------------------
  // Returns the row/col position of the given item in this note.
  public bool get_item_location( NoteItem item, out int row_pos, out int col_pos ) {
    row_pos = -1;
    col_pos = -1;
    for( int i=0; i<_rows.length; i++ ) {
      var row = _rows.index( i );
      for( int j=0; j<row.size(); j++ ) {
        if( row.get_item( j ) == item ) {
          row_pos = i; 
          col_pos = j;
          return( true );
        }
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Adds the row to the list of rows.
  public void add_row( NoteItemRow row, int pos = -1 ) {
    if( pos == -1 ) {
      _rows.append_val( row );
    } else {
      _rows.insert_val( pos, row );
    }
    modified = true;
  }

  //-------------------------------------------------------------
  // Adds a new note item, adding a new row if one is needed.
  public void add_item( NoteItem item, int row_pos, int col_pos, bool add_to_row ) {
    NoteItemRow row;
    if( add_to_row && (_rows.length > 0) ) {
      row = _rows.index( (row_pos == -1) ? (int)(_rows.length - 1) : row_pos );
    } else {
      row = new NoteItemRow( this );
      add_row( row, row_pos );
    }
    row.add_item( item, col_pos );
  }

  //-------------------------------------------------------------
  // Deletes the row from the list of rows.
  public void delete_row( int pos ) {
    _rows.remove_index( pos );
    modified = true;
  }

  //-------------------------------------------------------------
  // Deletes a single item from the note.  Removes the associated
  // row if it is the last item in the row.
  public void delete_item( int row_pos, int col_pos ) {
    var row = _rows.index( row_pos );
    row.delete_item( col_pos );
    if( row.size() == 0 ) {
      delete_row( row_pos );
    }
  }

  //-------------------------------------------------------------
  // Moves the row located at old_pos to the new position.
  public void move_row( int old_pos, int new_pos ) {
    var row = _rows.index( old_pos );
    if( old_pos < new_pos ) {
      new_pos++;
    }
    _rows.remove_index( old_pos );
    _rows.insert_val( new_pos, row );
  }

  //-------------------------------------------------------------
  // Returns a string containing the content of the note in Markdown format
  public string to_markdown( NotebookTree notebooks, bool front_matter, bool pandoc = false ) {
    var mod_title = _title.replace( "'", "''" );
    var str = "---\ntitle: '%s'\ncreated: '%s'\nupdated: '%s'\ntags: [%s]\n---\n\n".printf(
      mod_title, _created.to_string(), _updated.to_string(), _tags.to_markdown()
    );
    for( int i=0; i<_rows.length; i++ ) {
      var row = _rows.index( i );
      for( int j=0; j<row.size(); j++ ) {
        var item = row.get_item( j );
        str += "%s\n\n".printf( item.to_markdown( notebooks, pandoc ) );
      }
    }
    return( str );
  }

  //-------------------------------------------------------------
  // Exports this note to the given directory.
  public void export( NotebookTree notebooks, string dirname, string assets_dir ) throws FileError {
    var filename = Path.build_filename( dirname, "%s-%d.md".printf( _title.replace( " ", "-" ), _id ) );
    var str = "---\ntitle: '%s'\ncreated: '%s'\nupdated: '%s'\ntags: [%s]\n---\n\n".printf(
        _title, _created.to_string(), _updated.to_string(), _tags.to_markdown()
      );
    for( int i=0; i<_rows.length; i++ ) {
      var row = _rows.index( i );
      for( int j=0; j<row.size(); j++ ) {
        var item = row.get_item( j );
        str += "%s\n\n".printf( item.export( notebooks, assets_dir ) );
      }
    }
    FileUtils.set_contents( filename, str );
  }

  //-------------------------------------------------------------
  // Populates the given array with the list of languages that are used by the node.
  // We use a HashSet so that the final list of languages doesn't contain any duplicates.
  public void get_needed_languages( Gee.HashSet<string> langs ) {
    for( int i=0; i<_rows.length; i++ ) {
      var row = _rows.index( i );
      for( int j=0; j<row.size(); j++ ) {
        var item = (row.get_item( j ) as NoteItemCode);
        if( item != null ) {
          langs.add( item.lang );
        }
      }
    }
  }

  //-------------------------------------------------------------
  // Returns the result of comparing our note to the given note
  public static int compare( Note a, Note b ) {
    return( (int)(a._id > b._id) - (int)(a._id < b._id) );
  }

  //-------------------------------------------------------------
  // Returns true if this note contains a tag with the given string.
  public bool contains_tag( string tag ) {
    return( _tags.contains_tag( tag ) );
  }

  //-------------------------------------------------------------
  // Gets the note link titles from all of the note items.
  public void get_note_links( HashSet<string> note_titles ) {
    for( int i=0; i<_rows.length; i++ ) {
      var row = _rows.index( i );
      for( int j=0; j<row.size(); j++ ) {
        var item = row.get_item( j );
        item.get_note_links( note_titles );
      }
    }
  }

  //-------------------------------------------------------------
  // Adds the given note id to the list of referred links.
  public void add_referred( int id ) {
    if( _referred.add( id ) ) {
      _modified = true;
    }
  }

  //-------------------------------------------------------------
  // Removes the given note id from the list of referred links.
  public void remove_referred( int id ) {
    if( _referred.remove( id ) ) {
      _modified = true;
    }
  }

  //-------------------------------------------------------------
  // Saves the note in XML format
  public Xml.Node* save() {

    if( modified ) {
      _updated = new DateTime.now_local();
      modified = false;
    }

    Xml.Node* node  = new Xml.Node( null, "note" );
    Xml.Node* items = new Xml.Node( null, "items" );
    string[] referred_list = {};

    _referred.foreach((id) => {
      referred_list += id.to_string();
      return( true );
    });

    node->set_prop( "id",      _id.to_string() );
    node->set_prop( "title",   _title );
    node->set_prop( "created", _created.format_iso8601() );
    node->set_prop( "updated", _updated.format_iso8601() );
    node->set_prop( "viewed",  _viewed.format_iso8601() );
    node->set_prop( "locked",  _locked.to_string() );
    node->set_prop( "favorite", _favorite.to_string() );
    node->set_prop( "referred", string.joinv( ",", referred_list ) );

    node->add_child( _tags.save() );

    // Save the note items
    for( int i=0; i<_rows.length; i++ ) {
      node->add_child( _rows.index( i ).save() );
    }

    return( node );

  }

  // Loads the note from XML format
  private void load( Xml.Node* node ) {

    var i = node->get_prop( "id" );
    if( i != null ) {
      _id = int.parse( i );
    }

    var t = node->get_prop( "title" );
    if( t != null ) {
      title = t;
    }

    var c = node->get_prop( "created" );
    if( c != null ) {
      _created = new DateTime.from_iso8601( c, null );
    }

    var m = node->get_prop( "updated" );
    if( m != null ) {
      _updated = new DateTime.from_iso8601( m, null );
    }

    var v = node->get_prop( "viewed" );
    if( v != null ) {
      _viewed = new DateTime.from_iso8601( v, null );
    } else {
      _viewed = new DateTime.from_iso8601( _created.format_iso8601(), null );
    }

    var l = node->get_prop( "locked" );
    if( l != null ) {
      _locked = bool.parse( l );
    }

    var f = node->get_prop( "favorite" );
    if( f != null ) {
      _favorite = bool.parse( f );
    }

    var r = node->get_prop( "referred" );
    if( r != null ) {
      var referred_list = r.split( "," );
      foreach( var id in referred_list ) {
        _referred.add( int.parse( id ) );
      }
    }

    for( Xml.Node* it = node->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "tags" :  _tags.load( it );  break;
          case "row"  :  load_row( it );    break;
        }
      }
    }

  }

  //-------------------------------------------------------------
  // Loads the given row and appends it to our list of rows.
  private void load_row( Xml.Node* node ) {
    var row = new NoteItemRow.from_xml( this, node );
    _rows.append_val( row );
  }

}
