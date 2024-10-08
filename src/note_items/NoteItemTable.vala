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

public enum TableColumnType {
	TEXT,
	CHECKBOX,
	DATE,
	NUM;

	//-------------------------------------------------------------
	// Returns a stringified version of this value.
	public string to_string() {
		switch( this ) {
			case TEXT     :  return( "text" );
			case CHECKBOX :  return( "checkbox" );
			case DATE     :  return( "date" );
			default       :  assert_not_reached();
		}
	}

	//-------------------------------------------------------------
	// Returns a label that can be displayed within the UI.
	public string label() {
		switch( this ) {
			case TEXT     :  return( _( "Text" ) );
			case CHECKBOX :  return( _( "Checkbox" ) );
			case DATE     :  return( _( "Date" ) );
			default       :  assert_not_reached();
		}
	}

	//-------------------------------------------------------------
	// Parses the stringified version of a valid column type and returns
	// the associated value.
	public static TableColumnType parse( string val ) {
		switch( val ) {
			case "text"     :  return( TEXT );
			case "checkbox" :  return( CHECKBOX );
			case "date"     :  return( DATE );
			default         :  return( TEXT );
		}
	}

	//-------------------------------------------------------------
	// Generates the Markdown syntax based on this type and the string
	// value.
	public string to_markdown( string val ) {
		switch( this ) {
			case TEXT :
			  return( val );
			case CHECKBOX :
			  return( (val == "true") ? "[x]" : "[ ]" );
			case DATE :
			  return( val );  // The date will already be in YYYY/MM/DD format
			default :
			  assert_not_reached();
		}
	}

	//-------------------------------------------------------------
	// Parses the given value in Markdown format and returns the
	// string value.
	public string from_markdown( string val ) {
		switch( this ) {
			case TEXT     :  return( val );
			case CHECKBOX :
			  if( val.has_prefix( "[" ) && val.has_suffix( "]" ) ) {
			  	var inner = val.slice( val.index_of_nth_char( 1 ), val.index_of_nth_char( val.char_count() - 1 ) ).strip();
			  	return( (inner == "") ? "false" : "true" );
			  }
			  return( "false" );
			case DATE :
			  Date date = {};
			  date.set_parse( val );
			  if( date.valid() ) {
          return( "%d/%d/%d".printf( date.get_year(), date.get_month(), date.get_day() ) );
			  }
			  return( "" );
      default : assert_not_reached();
		}
	}

	//-------------------------------------------------------------
	// Returns true if this column type should be auto-expanded to
	// take up an equal share of available space.
	public bool is_expandable() {
		return( this == TEXT );
	}

	//-------------------------------------------------------------
	// Returns true if this column type should allow its size to be
	// resized.
	public bool is_resizable() {
		return( this == TEXT );
	}

}

//=============================================================

public class NoteItemTableColumn {

	private string            _header  = "";
	private Gtk.Justification _justify = Gtk.Justification.LEFT;
	private TableColumnType   _type    = TableColumnType.TEXT;

	public signal void changed();

	public string header {
		get {
			return( _header );
		}
		set {
			if( _header != value ) {
  			_header = value;
	  		changed();
	  	}
		}
	}

	public Gtk.Justification justify {
		get {
			return( _justify );
		}
		set {
			if( _justify != value ) {
				_justify = value;
				changed();
			}
		}
	}

	public TableColumnType data_type {
		get {
			return( _type );
		}
		set {
			if( _type != value ) {
				_type = value;
				changed();
			}
		}
	}

	//-------------------------------------------------------------
	// Default constructor
  public NoteItemTableColumn( int index = -1 ) {
    if( index != -1 ) {
    	_header = _( "Column %d" ).printf( index );
    }
  }

	//-------------------------------------------------------------
	// Loads the column information from XML data.
	public NoteItemTableColumn.from_xml( Xml.Node* node ) {
		load( node );
	}

	//-------------------------------------------------------------
	// Copy constructor
	public NoteItemTableColumn.copy( NoteItemTableColumn other ) {
		header  = other.header;
		justify = other.justify;
	}

	//-------------------------------------------------------------
	// Returns the justification string for the column.
	public string justify_string() {
		switch( _justify ) {
			case Gtk.Justification.LEFT   :  return( ":--" );
			case Gtk.Justification.CENTER :  return( ":-:" );
			case Gtk.Justification.RIGHT  :  return( "--:" );
			default                       :  return( ":--" );
		}
	}

	//-------------------------------------------------------------
	// Saves the column in XML format.
	public Xml.Node* save() {
		Xml.Node* node = new Xml.Node( null, "column" );
		node->set_prop( "header", _header );
		node->set_prop( "type",   _type.to_string() );
		switch( _justify ) {
			case Gtk.Justification.CENTER :  node->set_prop( "justify", "center" );  break;
			case Gtk.Justification.RIGHT  :  node->set_prop( "justify", "right" );   break;
			default                       :  node->set_prop( "justify", "left" );    break;
		}
		return( node );
	}

	//-------------------------------------------------------------
	// Loads the column from XML format.
	public void load( Xml.Node* node ) {
		var h = node->get_prop( "header" );
		if( h != null ) {
			_header = h;
		}
		var t = node->get_prop( "type" );
		if( t != null ) {
			_type = TableColumnType.parse( t );
		}
		var j = node->get_prop( "justify" );
		if( j != null ) {
			switch( j ) {
				case "center" :  _justify = Gtk.Justification.CENTER;  break;
				case "right"  :  _justify = Gtk.Justification.RIGHT;   break;
				default       :  _justify = Gtk.Justification.LEFT;    break;
			}
		}
	}

}

//=============================================================

public class NoteItemTableRow : Object {

	private Array<string> _values;

	//-------------------------------------------------------------
	// Default constructor
	public NoteItemTableRow( int cols = 0 ) {
		_values = new Array<string>();
		for( int i=0; i<cols; i++ ) {
			_values.append_val( "" );
		}
	}

	//-------------------------------------------------------------
	// Constructor from XML formatted data
	public NoteItemTableRow.from_xml( Xml.Node* node ) {
		_values = new Array<string>();
		load( node );
	}

	//-------------------------------------------------------------
	// Copies the given table row to ourselves
	public void copy( NoteItemTableRow other ) {
		_values.remove_range( 0, _values.length );
		for( int i=0; i<other.columns(); i++ ) {
			_values.append_val( other.get_value( i ) );
		}
	}

	//-------------------------------------------------------------
	// Searches for the given string in the specified column.
	public bool search( string str, bool[] check_cols ) {
		for( int i=0; i<_values.length; i++ ) {
			if( check_cols[i] && _values.index( i ).contains( str ) ) {
				return( true );
			}
		}
    return( false );
	}

	//-------------------------------------------------------------
	// Returns the number of columns in the row.
	public int columns() {
		return( (int)_values.length );
	}

	//-------------------------------------------------------------
	// Returns the value stored at the given column index
	public string get_value( int index ) {
		return( _values.index( index ) );
	}

	//-------------------------------------------------------------
	// Sets the value stored at the given column index to the given
	// value.
	public void set_value( int index, string val ) {
		_values.data[index] = val;
	}

	//-------------------------------------------------------------
	// Inserts a new column at the given index
	public void insert_column( int index, string val ) {
		_values.insert_val( index, val );
	}

	//-------------------------------------------------------------
	// Removes the column at the given index
	public void delete_column( int index ) {
		_values.remove_index( index );
	}

	//-------------------------------------------------------------
	// Returns the markdown for this row
	public string to_markdown( Array<NoteItemTableColumn> columns ) {
  	string[] cells = {};
		for( int i=0; i<_values.length; i++ ) {
			var col = columns.index( i );
			cells += col.data_type.to_markdown( _values.index( i ) );
 		}
 		return( "| " + string.joinv( "|", cells ) + " |" );
 	}

	//-------------------------------------------------------------
	// Saves the class information in XML format
	public Xml.Node* save() {
		Xml.Node* node = new Xml.Node( null, "row" );
		for( int i=0; i<_values.length; i++ ) {
			Xml.Node* cell = new Xml.Node( null, "cell" );
			cell->set_content( _values.index( i ) );
			node->add_child( cell );
		}
    return( node );
	}

	//-------------------------------------------------------------
	// Loads this class from XML formatted data.
	public void load( Xml.Node* node ) {
		for( Xml.Node* it = node->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "cell") ) {
      	_values.append_val( it->get_content() );
      }
		}
	}

}

//=============================================================

public class NoteItemTable : NoteItem {

	private string                     _description = "";
	private Array<NoteItemTableColumn> _columns;
	private ListStore                  _rows;
	private bool                       _auto_number = false;

	public string description {
		get {
			return( _description );
		}
		set {
			if( _description != value ) {
				_description = value;
				handle_change();
			}
		}
	}

	public ListStore model {
		get {
			return( _rows );
		}
	}

	public bool auto_number {
		get {
			return( _auto_number );
		}
		set {
			if( _auto_number != value ) {
				_auto_number = value;
				handle_change();
			}
		}
	}

	//-------------------------------------------------------------
	// Default constructor
	public NoteItemTable( Note note, int columns = 0, int rows = 0 ) {
		base( note, NoteItemType.TABLE );
		_columns = new Array<NoteItemTableColumn>();
		_rows    = new ListStore( typeof( NoteItemTableRow ) );
		for( int i=0; i<columns; i++ ) {
			var column = new NoteItemTableColumn( i );
			_columns.append_val( column );
			column.changed.connect( handle_change );
		}
		for( int i=0; i<rows; i++ ) {
			var row = new NoteItemTableRow( columns );
			_rows.append( row );
		}
	}

	//-------------------------------------------------------------
	// Constructor from XML node
	public NoteItemTable.from_xml( Note note, Xml.Node* node ) {
		base( note, NoteItemType.TABLE );
		_columns = new Array<NoteItemTableColumn>();
		_rows    = new ListStore( typeof( NoteItemTableRow ) );
		load( node );
	}

  //-------------------------------------------------------------
	// Copies the note item to this one
  public override void copy( NoteItem item ) {
    base.copy( item );
    var table = (item as NoteItemTable);
    if( table != null ) {
    	_columns.remove_range( 0, _columns.length );
    	_rows.remove_all();
    	for( int col=0; col<table.columns(); col++ ) {
		    var column = new NoteItemTableColumn.copy( table.get_column( col ) );
		    _columns.insert_val( col, column );
			  column.changed.connect( handle_change );
    	}
    }
  }

  //-------------------------------------------------------------
	// Used for string searching
	public override bool search( string pattern ) {
		if( description.contains( pattern ) ) {
			return( true );
		}
		bool[] check_cols = {};
		for( int i=0; i<columns(); i++ ) {
      check_cols += (_columns.index( i ).data_type == TableColumnType.TEXT);
		}
		for( int i=0; i<rows(); i++ ) {
			if( get_row( i ).search( pattern, check_cols ) ) {
				return( true );
			}
		}
    return( false );
	}

  //-------------------------------------------------------------
  // Called whenever something changes in the table.
  private void handle_change() {
  	modified = true;
  	changed();
  }

	//-------------------------------------------------------------
	// Returns the number of rows in the table.
	public int rows() {
		return( (int)_rows.get_n_items() );
	}

	//-------------------------------------------------------------
	// Returns the number of columns in the table.
	public int columns() {
		return( (int)_columns.length );
	}

	//-------------------------------------------------------------
	// Returns the column at the given index
	public NoteItemTableColumn get_column( int index ) {
		return( _columns.index( index ) );
	}

	//-------------------------------------------------------------
	// Returns the row at the given index
	public NoteItemTableRow get_row( int index ) {
		return( (NoteItemTableRow)_rows.get_item( index ) );
	}

	//-------------------------------------------------------------
	// Convenience functio that returns the cell value at the given
	// column and row.
	public string get_cell( int column, int row ) {
		return( get_row( row ).get_value( column ) );
	}

	//-------------------------------------------------------------
	// Convenience function to set the given cell to the specified
	// value.
	public void set_cell( int column, int row, string val ) {
		get_row( row ).set_value( column, val );
		handle_change();
	}

	//-------------------------------------------------------------
	// Gets the data for every row in the column.
	public void get_column_data( int column, Array<string> data ) {
		for( int i=0; i<rows(); i++ ) {
			var row = get_row( i );
			data.append_val( row.get_value( column ) );
		}
	}

	//-------------------------------------------------------------
	// Sets the column data to the given data.
	public void set_column_data( int column, Array<string> data ) {
		for( int i=0; ((i < rows()) && (i < data.length)); i++ ) {
		  get_row( i ).set_value( column, data.index( i ) );
		}
		handle_change();
	}

	//-------------------------------------------------------------
	// Inserts and empty blank column at the given index.
	public void insert_column( int index, string col_header, Gtk.Justification col_justify, TableColumnType col_type ) {
		var col = new NoteItemTableColumn() {
			header    = col_header,
			justify   = col_justify,
      data_type = col_type
		};
		_columns.insert_val( index, col );
		col.changed.connect( handle_change );
		for( int i=0; i<rows(); i++ ) {
			var row = get_row( i );
			row.insert_column( index, "" );
		}
		handle_change();
	}

	//-------------------------------------------------------------
	// Deletes the column at the given index.
	public void delete_column( int index ) {
		_columns.index( index ).changed.disconnect( handle_change );
		_columns.remove_index( index );
		for( int i=0; i<rows(); i++ ) {
			var row = get_row( i );
			row.delete_column( index );
		}
		handle_change();
	}

	//-------------------------------------------------------------
	// Inserts a blank row at the given index.
	public void insert_row( int index, NoteItemTableRow? row = null ) {
		var new_row = row ?? new NoteItemTableRow( (int)_columns.length );
		_rows.insert( index, new_row );
		handle_change();
	}

	//-------------------------------------------------------------
	// Deletes the row at the given index.
	public void delete_row( int index ) {
		_rows.remove( index );
		handle_change();
	}

	//-------------------------------------------------------------
	// Creates the markdown header.
	private string create_markdown_header() {
		string[] columns = {};
		string[] justs   = {};
		if( _auto_number ) {
			columns += "#";
      justs   += ":--";
		}
		for( int i=0; i<_columns.length; i++ ) {
			columns += _columns.index( i ).header;
			justs   += _columns.index( i ).justify_string();
		}
		return( "| " + string.joinv( "|", columns ) + " |\n| " + string.joinv( "|", justs ) + " |\n" );
	}

	//-------------------------------------------------------------
	// Converts the content to markdown text
	public override string to_markdown( NotebookTree? notebooks, bool pandoc ) {
		var str = create_markdown_header();
		if( _auto_number ) {
			for( int i=0; i<rows(); i++ ) {
				str += "| %d %s\n".printf( (i + 1), get_row( i ).to_markdown( _columns ) );
			}
		} else {
			for( int i=0; i<rows(); i++ ) {
				str += get_row( i ).to_markdown( _columns ) + "\n";
			}
		}
		return( str );
	}

	//-------------------------------------------------------------
	// Exports the table and returns the generated Markdown.
	public override string export( NotebookTree? notebooks, string assets_dir ) {
		return( to_markdown( notebooks, false ) );
	}

  //-------------------------------------------------------------
  // Saves the content in XML format
  public override Xml.Node* save() {

    Xml.Node* node  = base.save();
    Xml.Node* cnode = new Xml.Node( null, "columns" );
    Xml.Node* rnode = new Xml.Node( null, "rows" );

    node->set_prop( "description", _description );
    node->set_prop( "auto-number", _auto_number.to_string() );

    for( int i=0; i<_columns.length; i++ ) {
    	cnode->add_child( _columns.index( i ).save() );
    }
    node->add_child( cnode );

    for( int i=0; i<rows(); i++ ) {
    	rnode->add_child( get_row( i ).save() );
    }
    node->add_child( rnode );

    modified = false;

    return( node );
  }

  //-------------------------------------------------------------
  // Loads the columns node contents from XML formatted data
  private void load_columns( Xml.Node* node ) {
  	for( Xml.Node* it = node->children; it != null; it = it->next ) {
  		if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "column") ) {
    		var column = new NoteItemTableColumn.from_xml( it );
    		_columns.append_val( column );
    		column.changed.connect( handle_change );
    	}
  	}
  }

  //-------------------------------------------------------------
  // Loads the rows node contents from XML formatted data
  private void load_rows( Xml.Node* node ) {
  	for( Xml.Node* it = node->children; it != null; it = it->next ) {
  		if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "row") ) {
    		var row = new NoteItemTableRow.from_xml( it );
    		_rows.append( row );
    	}
  	}
  }

  //-------------------------------------------------------------
  // Loads the content from XML formatted data
  protected override void load( Xml.Node* node ) {

    base.load( node );

    var d = node->get_prop( "description" );
    if( d != null ) {
      _description = d;
    }

    var an = node->get_prop( "auto-number" );
    if( an != null ) {
    	_auto_number = bool.parse( an );
    }

    for( Xml.Node* it = node->children; it != null; it = it->next ) {
    	if( it->type == Xml.ElementType.ELEMENT_NODE ) {
    		switch( it->name ) {
    			case "columns" :  load_columns( it );  break;
    			case "rows"    :  load_rows( it );     break;
    		}
    	}
    }

  }

}