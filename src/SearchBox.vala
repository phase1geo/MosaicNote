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

using Gtk;

public enum SearchCategories {
  NOTEBOOK,
  CONTENT,
  TITLE,
  TAG,
  CREATED,
  FAVORITE,
  LOCKED,
  BLOCK,
  UPDATED,
  VIEWED,
  NUM;

  public string to_string() {
    switch( this ) {
      case NOTEBOOK :  return( _( "notebook" ) );
      case CONTENT  :  return( _( "content" ) );
      case TITLE    :  return( _( "title" ) );
      case TAG      :  return( _( "tag" ) );
      case CREATED  :  return( _( "created" ) );
      case FAVORITE :  return( _( "favorite" ) );
      case LOCKED   :  return( _( "locked" ) );
      case BLOCK    :  return( _( "block" ) );
      case UPDATED  :  return( _( "updated" ) );
      case VIEWED   :  return( _( "viewed" ) );
      default       :  assert_not_reached();
    }
  }
}

public enum SearchBoolean {
  TRUE,
  FALSE,
  NUM;

  public string to_string() {
    switch( this ) {
      case TRUE  :  return( _( "true" ) );
      case FALSE :  return( _( "false" ) );
      default    :  assert_not_reached();
    }
  }
}

//-------------------------------------------------------------
// Provides the search UI.
public class SearchBox : Box {

  private MainWindow  _win;
  private SearchEntry _search_entry;
  private Label       _suggest;
  private Label       _error;
  private Calendar    _calendar;
  private ListBox     _list;

  private SmartParserSuggestion _suggestion;
  private int                   _start_char;
  private string                _pattern;
  private Array<string>         _tag_matches;
  private Array<string>         _list_values;
  private SmartNotebook?        _notebook = null;

  public signal void hide_search();

  public SmartNotebook? notebook {
    set {
      _notebook = value;
    }
  }

  //-------------------------------------------------------------
  // Default constructor
  public SearchBox( MainWindow win ) {

    Object( orientation: Orientation.VERTICAL, spacing: 5 );

    _win = win;

    _tag_matches = new Array<string>();
    _list_values = new Array<string>();

    _search_entry = new SearchEntry() {
      placeholder_text = _( "Enter Search Query" ),
      width_chars = 50
    };

    var search_key = new EventControllerKey();
    _search_entry.add_controller( search_key );

    _search_entry.activate.connect(() => {
      Idle.add(() => {
        var nb = _notebook ?? win.smart_notebooks.get_search_notebook();
        win.parser.parse( _search_entry.text, false );
        win.parser.populate_smart_notebook( nb );
        win.notes.populate_with_notebook( nb );
        _notebook = null;
        return( false );
      });
      hide_search();
    });

    _search_entry.search_changed.connect(() => {
      var text = _search_entry.text;
      var end  = text.index_of_nth_char( _search_entry.cursor_position );
      win.parser.parse( text.slice( 0, end ), true );
    });

    search_key.key_pressed.connect((keyval, keycode, state) => {
      switch( keyval ) {
        case Gdk.Key.Escape :
          hide_search();
          return( true );
        case Gdk.Key.Tab :
          return( _list.visible && activate_selected_row() );
        case Gdk.Key.Down :
          return( _list.visible && select_list_row( 1 ) );
        case Gdk.Key.Up : 
          return( _list.visible && select_list_row( -1 ) );
      }
      return( false );
    });

    _calendar = new Calendar() {
      halign = Align.START,
      hexpand = true,
      margin_start = 20
    };

    _calendar.day_selected.connect(() => {
      var dt    = _calendar.get_date();
      var str   = dt.format( "%Y/%m/%d" );
      var text  = _search_entry.text;
      var start = text.index_of_nth_char( _start_char );
      var end   = text.index_of_nth_char( _start_char + _pattern.char_count() );
      var cursor = _start_char + str.char_count();
      if( text.get_char( end ) == ']' ) {
        cursor++;
      }
      _search_entry.text = text.splice( start, end, str );
      _search_entry.set_position( cursor );
      _search_entry.grab_focus();
    });

    _list = new ListBox() {
      selection_mode = SelectionMode.SINGLE,
      halign = Align.FILL,
      valign = Align.FILL
    };

    _list.row_activated.connect( list_activated );

    var suggest_box = new Box( Orientation.VERTICAL, 0 );
    suggest_box.append( _calendar );
    suggest_box.append( _list );

    _suggest = new Label( "" );
    _error   = new Label( "" );

    append( _search_entry );
    append( suggest_box );
    append( _suggest );
    append( _error );

    win.parser.suggest.connect( handle_suggestion );
    win.parser.parse_result.connect( handle_parser_result );

  }

  //-------------------------------------------------------------
  // Initializes the widget for search.
  public void initialize( string with_string = "" ) {
    _suggest.label = "";
    _error.label = "";
    handle_suggestion( SmartParserSuggestion.CATEGORY, 0, "" );
    _search_entry.text = with_string;
    _search_entry.grab_focus();
  }

  //-------------------------------------------------------------
  // Activates the currently selected row
  private bool activate_selected_row() {
    var row = _list.get_selected_row();
    if( row != null ) {
      _list.row_activated( row );
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Changes the selection to move in the given direction.
  private bool select_list_row( int dir ) {
    var row = _list.get_selected_row();
    if( row != null ) {
      do {
        row = _list.get_row_at_index( row.get_index() + dir );
      } while( (row != null) && !row.selectable );
      if( row != null ) {
        _list.select_row( row );
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Handles parser suggestions and updates our UI accordingly.
  private void handle_suggestion( SmartParserSuggestion suggestion, int start_char, string pattern ) {

    _suggestion = suggestion;
    _start_char = start_char;
    _pattern    = pattern;

    reset_results();

    switch( suggestion ) {
      case SmartParserSuggestion.CATEGORY   :  show_categories( start_char, pattern );  break;
      case SmartParserSuggestion.TAG        :  show_tags( true, start_char, pattern );  break;
      case SmartParserSuggestion.TAG_ONLY   :  show_tags( false, start_char, pattern );  break;
      case SmartParserSuggestion.DATE       :
      case SmartParserSuggestion.DATE_ONLY  :
      case SmartParserSuggestion.DATE_ABS   :
      case SmartParserSuggestion.DATE_REL   :  show_date( suggestion, start_char, pattern );  break;
      case SmartParserSuggestion.BOOLEAN    :  show_boolean( start_char, pattern );  break;
      case SmartParserSuggestion.NOTEBOOK   :  show_notebook( start_char, pattern );  break;
      case SmartParserSuggestion.TEXT       :  show_text( start_char, pattern );  break;
      case SmartParserSuggestion.BLOCK      :  show_block( true, start_char, pattern );  break;
      case SmartParserSuggestion.BLOCK_ONLY :  show_block( false, start_char, pattern );  break;
      case SmartParserSuggestion.NONE       :  show_none();  break;
      default                               :  break;
    }

  }

  //-------------------------------------------------------------
  // Called whenever a list item is activated.  Inserts the string
  // value at the selected index into the search entry.
  private void list_activated( ListBoxRow row ) {
    var str    = _list_values.index( row.get_index() );
    var text   = _search_entry.text;
    var start  = text.index_of_nth_char( _start_char );
    var end    = text.index_of_nth_char( _start_char + _pattern.char_count() );
    var cursor = _start_char + str.char_count();
    _search_entry.text = text.splice( start, end, str );
    if( str.has_suffix( "]" ) ) {
      cursor--;
    }
    _search_entry.set_position( cursor );
    _search_entry.grab_focus();
  }

  //-------------------------------------------------------------
  // Handles error detection information.
  private void handle_parser_result( string message, int start_char ) {
    _error.label = "";
    if( start_char != -1 ) {
      _error.label = "error: %s, start: %d".printf( message, start_char );
    }
  }

  //-------------------------------------------------------------
  // Clears the search results area
  private void reset_results() {

    _calendar.visible = false;
    _list.visible     = false;

    Utils.clear_listbox( _list );

    if( _list_values.length > 0 ) {
      _list_values.remove_range( 0, _list_values.length );
    }

  }

  //-------------------------------------------------------------
  // Constructs an item to add to the list which is a header and
  // adds it, making it unselectable and unactivatable.
  private void make_list_header( string name ) {

    var label = new Label( Utils.make_title( name ) ) {
      halign = Align.START,
      use_markup = true,
      margin_top = 10,
      margin_bottom = 5
    };

    _list.append( label );
    _list.visible = true;

    var row = _list.get_row_at_index( (int)_list_values.length );
    row.activatable = false;
    row.selectable  = false;

    _list_values.append_val( "" );

  }

  //-------------------------------------------------------------
  // Constructs an item to add to the list and adds it.
  private void make_list_item( string action, string insert_str = "", string? detail = null ) {

    var text  = action;
    var row   = _list.get_row_at_index( (int)_list_values.length - 1 );
    var first = (row == null) || !row.selectable;

    if( detail != null ) {
      text += "\n   %s".printf( Utils.make_italicized( detail ) );
    }

    var label = new Label( text ) {
      halign        = Align.START,
      justify       = Justification.LEFT,
      margin_top    = 3,
      margin_bottom = 3,
      margin_start  = 20,
      use_markup    = true
    };

    _list.append( label );

    if( first && (_list_values.length <= 1) ) {
      var new_row = _list.get_row_at_index( (int)_list_values.length );
      _list.select_row( new_row );
    }

    _list_values.append_val( insert_str );

  }

  //-------------------------------------------------------------
  // If there are no results displayed, add an item stating that
  // there are no matching results and make it invalid from use.
  private void make_list_none_found() {

    var row = _list.get_row_at_index( (int)_list_values.length - 1 );

    if( (row == null) || !row.selectable ) {

      var label = new Label( Utils.make_italicized( _( "No matches found" ) ) ) {
        halign = Align.START,
        margin_top    = 3,
        margin_bottom = 3,
        margin_start  = 20,
        use_markup = true
      };

      _list.append( label );

      var none_row = _list.get_row_at_index( (int)_list_values.length );
      none_row.activatable = false;
      none_row.selectable  = false;

      _list_values.append_val( "" );

    }

  }

  //-------------------------------------------------------------
  // Displays available categories.
  private void show_categories( int start_char, string pattern ) {

    _suggest.label = "show_categories, start_char: %d, pattern: (%s)".printf( start_char, pattern );

    make_list_header( _( "Insert Category" ) );

    for( int i=0; i<SearchCategories.NUM; i++ ) {
      var category = (SearchCategories)i;
      if( category.to_string().contains( pattern ) ) {
        make_list_item( category.to_string(), (category.to_string() + ":") );
      }
    }

    make_list_none_found();

  }

  //-------------------------------------------------------------
  // Displays available tags
  private void show_tags( bool include_not, int start_char, string pattern ) {

    if( include_not ) {
      make_list_header( _( "Operations" ) );
      make_list_item( _( "Search for notes that do not contain a tag" ), "!" );
    }

    make_list_header( _( "Insert Tag" ) );

    _win.full_tags.get_matches( _tag_matches, pattern );
    for( int i=0; i<_tag_matches.length; i++ ) {
      if( _tag_matches.index( i ).contains( pattern ) ) {
        var tag   = _tag_matches.index( i );
        make_list_item( tag, (tag + " ") );
      }
    }

    make_list_none_found();

  }

  //-------------------------------------------------------------
  // Displays date options
  private void show_date( SmartParserSuggestion date_type, int start_char, string pattern ) {

    _suggest.label = "show_date, date_type: %s, start_char: %d, pattern: (%s)".printf( date_type.to_string(), start_char, pattern );

    if( (date_type == SmartParserSuggestion.DATE) || (date_type == SmartParserSuggestion.DATE_ONLY) ) {

      _calendar.visible = true;

      if( date_type == SmartParserSuggestion.DATE ) {
        make_list_header( _( "Operations" ) );
        make_list_item( _( "Search for notes that are not in the date range" ), "!" );
      }

      make_list_header( _( "Insert Date Range" ) );

      for( int i=0; i<DateMatchType.NUM; i++ ) {
        var match_type = (DateMatchType)i;
        var type_value = match_type.search_string();
        if( type_value != null ) {
          make_list_item( type_value, "%s[]".printf( type_value ), match_type.search_detail() );
        }
      }

      make_list_none_found();

    } else if( date_type == SmartParserSuggestion.DATE_ABS ) {

      _calendar.visible = true;

    } else if( date_type == SmartParserSuggestion.DATE_REL ) {

      make_list_header( _( "Insert Relative Time Period" ) );

      for( int i=0; i<TimeType.NUM; i++ ) {
        var time_type = (TimeType)i;
        var time_value = time_type.search_string();
        if( time_value != null ) {
          make_list_item( time_value, time_value, time_type.search_detail() );
        }
      }

      make_list_none_found();

    }

  }

  //-------------------------------------------------------------
  // Displays boolean options
  private void show_boolean( int start_char, string pattern ) {

    make_list_header( _( "Insert Boolean" ) );

    for( int i=0; i<SearchBoolean.NUM; i++ ) {
      var boolean = (SearchBoolean)i;
      if( boolean.to_string().contains( pattern ) ) {
        make_list_item( boolean.to_string(), (boolean.to_string() + " ") );
      }
    }

    make_list_none_found();

  }

  //-------------------------------------------------------------
  // Displays notebook options
  private void show_notebook( int start_char, string pattern ) {

    var paths = new Array<string>();
    _win.notebooks.get_notebook_paths( paths );

    make_list_header( _( "Insert Notebook" ) );

    for( int i=0; i<paths.length; i++ ) {
      var path = paths.index( i );
      if( path.contains( pattern ) ) {
        make_list_item( path, (path.contains( " " ) ? ("\"" + path + "\"" + " ") : (path + " ")) );
      }
    }

    make_list_none_found();

  }

  //-------------------------------------------------------------
  // Displays text options
  private void show_text( int start_char, string pattern ) {

    if( pattern == "" ) {
      make_list_header( _( "Modifiers" ) );
      make_list_item( _( "Insert regular expression" ), "re[]" );
    }

  }

  //-------------------------------------------------------------
  // Displays block options
  private void show_block( bool include_not, int start_char, string pattern ) {

    if( include_not ) {
      make_list_header( _( "Modifiers" ) );
      make_list_item( _( "Search for notes that do not contain a block type" ), "!" );
    }

    make_list_header( _( "Insert Block" ) );

    for( int i=0; i<NoteItemType.NUM; i++ ) {
      var item_type = (NoteItemType)i;
      if( item_type.search_string().contains( pattern ) ) {
        make_list_item( item_type.to_string(), (item_type.to_string() + " ") );
      }
    }

    make_list_none_found();

  }

  //-------------------------------------------------------------
  // Clears the displayed options
  private void show_none() {
    _suggest.label = "";
  }

}