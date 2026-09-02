/*
* Copyright (c) 2026 (https://github.com/phase1geo/MosaicNote)
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

using Gtk;

public class OutlineHeader : Object {

  public int    row    { get; private set; default = -1; }
  public int    col    { get; private set; default = -1; }
  public int    offset { get; private set; default = -1; }
  public int    depth  { get; private set; default = 0; }
  public string prefix { get; private set; default = ""; }
  public string title  { get; private set; default = ""; }

  //-------------------------------------------------------------
  // Constructor
  public OutlineHeader( int r, int c, int o, int d, string t, string p = "" ) {
    row    = r;
    col    = c;
    offset = o;
    depth  = d;
    prefix = p;
    title  = t;
  }

  //-------------------------------------------------------------
  // Returns the label to display in the outline viewer.
  public string label() {
    var indent     = string.nfill( (depth * 5), ' ' );
    var title_type = (prefix == "") ? "" : "<u>%s</u>: ".printf( prefix );
    return( "%s%s%s".printf( indent, title_type, "<b>" + title + "</b>" ) );
  }

  //-------------------------------------------------------------
  // Returns the header as a debug string.
  public string to_string() {
    var prefix = string.nfill( depth, ' ' );
    return( "%s, row=%d, col=%d, offset=%d".printf( label(), row, col, offset ) );
  }

}

public class Outline : Gtk.Window {

  private MainWindow     _win;
  private Note           _note;
  private Regex          _header_re;
  private ListBox        _list;
  private GLib.ListStore _model;

  public signal void header_selected( int row, int col, int line );

  //-------------------------------------------------------------
  // Constructor
  public Outline( MainWindow win, Note note ) {

    Object(
      transient_for: win,
      title: _( "Note Outline" )
    );

    _win  = win;
    _note = note;

    try {
      _header_re = new Regex( """^(#{1,6})\s+(.*)(\s+\1)?$""" );
    } catch( RegexError e ) {
      assert_not_reached();
    }

    // Create the UI
    _list = new ListBox() {
      valign = Align.FILL,
      vexpand = true,
      focusable = true,
      selection_mode = SelectionMode.BROWSE,
      activate_on_single_click = true,
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };

    _list.row_activated.connect((row) => {
      var header = (OutlineHeader)_model.get_item( row.get_index() );
      header_selected( header.row, header.col, header.offset );
    });

    child = _list;

    _model = new GLib.ListStore( typeof( OutlineHeader ) );
    _list.bind_model( _model, create_header );

    parse_note();

  }

  //-------------------------------------------------------------
  // Creates the header widget from the given object.
  private Widget create_header( Object obj ) {

    var header = (OutlineHeader)obj;

    var lbl = new Label( header.label() ) {
      halign        = Align.START,
      use_markup    = true,
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };

    return( lbl );

  }

  //-------------------------------------------------------------
  // Gets the headers from the given assets item.
  private void parse_note_assets( NoteItem item, int row, int col, ref int depth ) {
    var assets_item = (item as NoteItemAssets);
    if( (assets_item != null) && (assets_item.description != "") ) {
      var header = new OutlineHeader( row, col, -1, depth, assets_item.description, _( "Assets" ) );
      _model.append( header );
    }
  }

  //-------------------------------------------------------------
  // Gets the headers from the given assets item.
  private void parse_note_code( NoteItem item, int row, int col, ref int depth ) {
    var code_item = (item as NoteItemCode);
    if( (code_item != null) && (code_item.description != "") ) {
      var header = new OutlineHeader( row, col, -1, depth, code_item.description, _( "Code" ) );
      _model.append( header );
    }
  }

  //-------------------------------------------------------------
  // Gets the headers from the given assets item.
  private void parse_note_image( NoteItem item, int row, int col, ref int depth ) {
    var image_item = (item as NoteItemImage);
    if( (image_item != null) && (image_item.description != "") ) {
      var header = new OutlineHeader( row, col, -1, depth, image_item.description, _( "Image" ) );
      _model.append( header );
    }
  }

  //-------------------------------------------------------------
  // Gets the headers from the given Markdown item.  Updates the
  // given depth to be one more than the last header depth found.
  private void parse_note_markdown( NoteItem item, int row, int col, ref int depth ) {
    var md_item = (item as NoteItemMarkdown);
    if( md_item != null ) {
      MatchInfo match;
      var lines       = md_item.content.split( "\n" );
      var offset      = 0;
      var last_line   = "";
      var last_offset = 0;
      foreach( var line in lines ) {
        if( _header_re.match( line, 0, out match ) ) {
          depth = match.fetch( 1 ).char_count() - 1;
          var header = new OutlineHeader( row, col, offset, depth, match.fetch( 2 ).strip() );
          _model.append( header );
          depth++;
          last_line = "";
        } else if( line.has_prefix( "=" ) && (last_line != "") ) {
          var header = new OutlineHeader( row, col, last_offset, 0, last_line );
          _model.append( header );
          depth = 1;
          last_line = "";
        } else if( line.has_prefix( "-" ) ) {
          if( last_line != "" ) {
            var header = new OutlineHeader( row, col, last_offset, 1, last_line );
            _model.append( header );
            depth = 2;
          }
          last_line = "";
        } else {
          last_line = line.strip();
        }
        last_offset = offset;
        offset += line.char_count() + 1;
      }
    }
  }

  //-------------------------------------------------------------
  // Gets the headers from the given math item.
  private void parse_note_math( NoteItem item, int row, int col, ref int depth ) {
    var math_item = (item as NoteItemMath);
    if( (math_item != null) && (math_item.description != "") ) {
      var header = new OutlineHeader( row, col, -1, depth, math_item.description, _( "Formula" ) );
      _model.append( header );
    }
  }

  //-------------------------------------------------------------
  // Gets the headers from the given assets item.
  private void parse_note_table( NoteItem item, int row, int col, ref int depth ) {
    var table_item = (item as NoteItemTable);
    if( (table_item != null) && (table_item.description != "") ) {
      var header = new OutlineHeader( row, col, -1, depth, table_item.description, _( "Table" ) );
      _model.append( header );
    }
  }

  //-------------------------------------------------------------
  // Gets the headers from the given assets item.
  private void parse_note_uml( NoteItem item, int row, int col, ref int depth ) {
    var uml_item = (item as NoteItemUML);
    if( (uml_item != null) && (uml_item.description != "") ) {
      var header = new OutlineHeader( row, col, -1, depth, uml_item.description, _( "Figure" ) );
      _model.append( header );
    }
  }

  //-------------------------------------------------------------
  // Parses the note for headers and descriptions.
  private void parse_note() {

    var depth = 0;

    _model.remove_all();

    for( int i=0; i<_note.rows(); i++ ) {
      var row = _note.get_row( i );
      for( int j=0; j<row.size(); j++ ) {
        var item = row.get_item( j );
        switch( item.item_type ) {
          case NoteItemType.ASSETS   :  parse_note_assets( item, i, j, ref depth );    break;
          case NoteItemType.CODE     :  parse_note_code( item, i, j, ref depth );      break;
          case NoteItemType.IMAGE    :  parse_note_image( item, i, j, ref depth );     break;
          case NoteItemType.MARKDOWN :  parse_note_markdown( item, i, j, ref depth );  break;
          case NoteItemType.MATH     :  parse_note_math( item, i, j, ref depth );      break;
          case NoteItemType.TABLE    :  parse_note_table( item, i, j, ref depth );     break;
          case NoteItemType.UML      :  parse_note_uml( item, i, j, ref depth );       break;
          default                    :  assert_not_reached();
        }
      }
    }

  }

  //-------------------------------------------------------------
  // Returns string version of the parse header contents, useful
  // for debugging.
  private string to_string() {
    var str = "";
    for( int i=0; i<_model.n_items; i++ ) {
      var header = (OutlineHeader)_model.get_item( i );
      str += header.to_string() + "\n";
    }
    return( str );
  }

}
