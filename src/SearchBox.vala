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

//-------------------------------------------------------------
// Provides the search UI.
public class SearchBox : Box {

  private MainWindow  _win;
  private SearchEntry _search_entry;
  private Label       _suggest;
  private Label       _error;

  private SmartParserSuggestion _suggestion;
  private Array<string>         _tag_matches;

  public signal void hide_search();

  //-------------------------------------------------------------
  // Default constructor
  public SearchBox( MainWindow win ) {

    Object( orientation: Orientation.VERTICAL, spacing: 5 );

    _win = win;

    _tag_matches = new Array<string>();

    var search_nb = new SmartNotebook( "search", SmartNotebookType.USER, _win.notebooks );

    _search_entry = new SearchEntry() {
      placeholder_text = _( "Enter Search Query" ),
      width_chars = 50
    };

    var search_key = new EventControllerKey();
    _search_entry.add_controller( search_key );

    _search_entry.activate.connect(() => {
      Idle.add(() => {
        win.parser.parse( _search_entry.text, false );
        win.parser.populate_smart_notebook( search_nb );
        win.notes.populate_with_notebook( search_nb );
        return( false );
      });
      hide_search();
    });

    _search_entry.search_changed.connect(() => {
      win.parser.parse( _search_entry.text, true );
    });

    search_key.key_pressed.connect((keyval, keycode, state) => {
      if( keyval == Gdk.Key.Escape ) {
        hide_search();
        return( true );
      }
      return( false );
    });

    _suggest = new Label( "" );
    _error   = new Label( "" );

    append( _search_entry );
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
  }

  //-------------------------------------------------------------
  // Handles parser suggestions and updates our UI accordingly.
  private void handle_suggestion( SmartParserSuggestion suggestion, int start_char, string pattern ) {
    _suggestion = suggestion;
    switch( suggestion ) {
      case SmartParserSuggestion.CATEGORY   :  show_categories( start_char, pattern );  break;
      case SmartParserSuggestion.TAG        :  show_tags( true, start_char, pattern );  break;
      case SmartParserSuggestion.TAG_ONLY   :  show_tags( false, start_char, pattern );  break;
      case SmartParserSuggestion.DATE       :
      case SmartParserSuggestion.DATE_ABS   :
      case SmartParserSuggestion.DATE_REL   :  show_date( suggestion, start_char, pattern );  break;
      case SmartParserSuggestion.BOOLEAN    :  show_boolean( start_char, pattern );  break;
      case SmartParserSuggestion.NOTEBOOK   :  show_notebook( start_char, pattern );  break;
      case SmartParserSuggestion.TEXT       :  show_text( start_char, pattern );  break;
      case SmartParserSuggestion.BLOCK      :  show_block( true, start_char, pattern );  break;
      case SmartParserSuggestion.BLOCK_ONLY :  show_block( false, start_char, pattern );  break;
      case SmartParserSuggestion.NONE       :  show_none();  break;
    }
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
  // Displays available categories.
  private void show_categories( int start_char, string pattern ) {
    _suggest.label = "show_categories, start_char: %d, pattern: (%s)".printf( start_char, pattern );
  }

  //-------------------------------------------------------------
  // Displays available tags
  private void show_tags( bool include_not, int start_char, string pattern ) {
    _suggest.label = "show_tags, include_not: %s, start_char: %d, pattern: (%s)".printf( include_not.to_string(), start_char, pattern );
    _win.full_tags.get_matches( _tag_matches, pattern );
    for( int i=0; i<_tag_matches.length; i++ ) {
      if( _tag_matches.index( i ) == pattern ) {
        show_none();
        break;
      }
    }
  }

  //-------------------------------------------------------------
  // Displays date options
  private void show_date( SmartParserSuggestion date_type, int start_char, string pattern ) {
    _suggest.label = "show_date, date_type: %s, start_char: %d, pattern: (%s)".printf( date_type.to_string(), start_char, pattern );
  }

  //-------------------------------------------------------------
  // Displays boolean options
  private void show_boolean( int start_char, string pattern ) {
    _suggest.label = "show_boolean, start_char: %d, pattern: (%s)".printf( start_char, pattern );
  }

  //-------------------------------------------------------------
  // Displays notebook options
  private void show_notebook( int start_char, string pattern ) {
    _suggest.label = "show_notebook, start_char: %d, pattern: (%s)".printf( start_char, pattern );
  }

  //-------------------------------------------------------------
  // Displays text options
  private void show_text( int start_char, string pattern ) {
    _suggest.label = "show_text, start_char: %d, pattern: (%s)".printf( start_char, pattern );
  }

  //-------------------------------------------------------------
  // Displays block options
  private void show_block( bool include_not, int start_char, string pattern ) {
    _suggest.label = "show_block, include_not: %s, start_char: %d, pattern: (%s)".printf( include_not.to_string(), start_char, pattern );
  }

  //-------------------------------------------------------------
  // Clears the displayed options
  private void show_none() {
    _suggest.label = "";
  }

}