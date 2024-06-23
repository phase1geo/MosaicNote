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

public enum SmartParserSuggestion {
  CATEGORY,   // Suggest: "title", "block", "created", etc.
  TAG,        // Suggest: !<tag> or <tag>, perhaps even show matching tags
  TAG_ONLY,   // Suggest: <tag>
  DATE,       // Suggest: calendar, "is[", "before[", "after[", "last[", "between[", etc.
  DATE_ABS,   // Suggest: absolute dates
  DATE_REL,   // Suggest: relative dates
  BOOLEAN,    // Suggest: "true", "false", "0" or "1"
  NOTEBOOK,   // Suggest: available matching notebooks by name or by path
  TEXT,       // Suggest: "re[" or other text
  BLOCK,      // Suggest: ! and names of available blocks
  BLOCK_ONLY, // Suggest: names of available blocks
  NONE,       // Disable suggestions (used when a token is good)
  NUM;

  public string to_string() {
    switch( this ) {
      case CATEGORY   :  return( "category" );
      case TAG        :  return( "tag" );
      case TAG_ONLY   :  return( "tag-only" );
      case DATE       :  return( "date" );
      case DATE_ABS   :  return( "date-abs" );
      case DATE_REL   :  return( "date-rel" );
      case BOOLEAN    :  return( "boolean" );
      case NOTEBOOK   :  return( "notebook" );
      case TEXT       :  return( "text" );
      case BLOCK      :  return( "block" );
      case BLOCK_ONLY :  return( "block-only" );
      default         :  assert_not_reached();
    }
  }
}

public class SmartParser {

  private NotebookTree           _notebooks;
  private List<SmartLogicFilter> _stack;

  private string _error_message    = "";
  private int    _error_start      = -1;
  private int    _prev_error_start = -1;

  public signal void suggest( SmartParserSuggestion suggestion, int start_char, string pattern );
  public signal void parse_result( string message, int start_char );

  //-------------------------------------------------------------
  // Default constructor
  public SmartParser( NotebookTree notebooks ) {
    _notebooks = notebooks;
    _stack = new List<SmartLogicFilter>();
  }

  //-------------------------------------------------------------
  // Parses the given search string and constructs a smart filter
  // 
  public bool parse( string search_str, bool check_syntax_only ) {

    var in_double   = false;
    var in_single   = false;
    var skip_char   = false;
    var token       = "";
    var index       = 0;
    var token_start = 0;

    if( !check_syntax_only ) {
      var and_filter = new FilterAnd();
      _stack.append( and_filter );
    } else {
      _prev_error_start = _error_start;
      _error_message    = "";
      _error_start      = -1;
      if( search_str == "" ) {
        suggest( SmartParserSuggestion.CATEGORY, 0, "" );
      }
    }

    for( int i=0; i<search_str.length; i++ ) {
      if( search_str.valid_char( i ) ) {
        var ch = search_str.get_char( i );
        if( skip_char ) {
          token += ch.to_string();
          skip_char = false;
        } else {
          switch( ch ) {
            case ' ' :
              if( !in_double && !in_single && (token != "") ) {
                parse_token( token, token_start, check_syntax_only );
                token = "";
                if( check_syntax_only ) {
                  suggest( SmartParserSuggestion.CATEGORY, (index + 1), "" );
                }
              } else {
                token += " ";
              }
              break;
            case '"'  :
              if( !in_single ) {
                in_double = !in_double;
              } else {
                token += "\"";
              }
              break;
            case '\'' :
              if( !in_double ) {
                in_single = !in_single;
              } else {
                token += "'";
              }
              break;
            case '('  :
              if( !in_single && !in_double ) {
                if( !check_syntax_only ) {
                  push_filter( false );
                }
              } else {
                token += "(";
              }
              break;
            case ')'  :
              if( !in_single && !in_double ) {
                parse_token( token, token_start, check_syntax_only );
                token = "";
                if( !check_syntax_only ) {
                  pop_filter();
                }
              } else {
                token += ")";
              }
              break;
            case '!'  :
              if( !in_single && !in_double && (token == "") ) {
                if( !check_syntax_only ) {
                  push_filter( true );
                }
              } else {
                token += "!";
              }
              break;
            case '\\' :  skip_char = true;  token += ch.to_string();  break;
            default   :  token += ch.to_string();  break;
          }
        }
        index++;
        if( token == "" ) {
          token_start = index;
        }
      }
    }

    stdout.printf( "token: %s, token_start: %d\n", token, token_start );

    if( token != "" ) {
      parse_token( token, token_start, check_syntax_only );
    }

    if( !check_syntax_only ) {
      pop_all();
      stdout.printf( "----------------------------------\n" );
      stdout.printf( "FILTER: %s\n", _stack.nth_data( 0 ).to_string() );
    } else if( (_error_start != -1) || (_prev_error_start != -1) ) {
      parse_result( _error_message, _error_start );
    }

    return( ((_stack.length() == 1) || check_syntax_only) && !in_double && !in_single && !skip_char );

  }

  //-------------------------------------------------------------
  // Populates the given smart notebook with the matching notes
  // within the list of available notebooks.
  public void populate_smart_notebook( SmartNotebook notebook ) {
    unowned var last = _stack.last();
    if( (last != null) && ((last.data as SmartLogicFilter) != null) ) {
      notebook.filter = (SmartLogicFilter)last.data;
      _notebooks.populate_smart_notebook( notebook );
      _stack.remove( last.data );
    }
  }

  //-------------------------------------------------------------
  // Pushes an AND logic filter onto the stack.  If push_not is
  // set, we will add a NOT logic filter to the stack followed
  // by an AND filter
  private void push_filter( bool push_not ) {
    var and_filter = new FilterAnd();
    if( push_not ) {
      var not_filter = new FilterNot();
      _stack.append( not_filter );
    }
    _stack.append( and_filter );
  }

  //-------------------------------------------------------------
  // Pops the top of the stack and adds it to the new top of stack.
  private void pop_filter() {
    unowned var last = _stack.last();
    if( last != null ) {
      var pop_filter = (last.data as SmartLogicFilter);
      if( pop_filter != null ) {
        _stack.remove( last.data );
        if( (((pop_filter as FilterAnd) != null) || ((pop_filter as FilterOr) != null)) && (pop_filter.size() == 1) ) {
          add_filter_to_stack_top( pop_filter.get_filter( 0 ) );
        } else {
          add_filter_to_stack_top( pop_filter );
        }
      }
    }
  }

  //-------------------------------------------------------------
  // Pops all of the stack items until the stack is a length of 1.
  private void pop_all() {
    while( _stack.length() > 1 ) {
      pop_filter();
    }
  }

  //-------------------------------------------------------------
  // Parses the given search token and adds it to the top of the stack.
  private bool parse_token( string token, int start_char, bool check_syntax_only ) {

    if( token.get_char( 0 ) == '#' ) {
      var tag = token.substring( token.index_of_nth_char( 1 ) );
      return( parse_tag( tag, (start_char + 1), check_syntax_only ) );
    }

    if( token.get_char( 0 ) == '@' ) {
      var date = token.substring( token.index_of_nth_char( 1 ) );
      return( parse_date( "created", date, (start_char + 1), check_syntax_only ) );
    }

    if( (token.down() == "and") || (token == "&") || (token == "&&") ) {
      // An AND should always be at the top of the stack
      return( true );
    }

    if( (token.down() == "or") || (token == "|") || (token == "||") ) {
      // AND operations take precedence over OR operations, so if we encounter an OR
      // and the top of the stack is not an OR filter, we need to create the OR, place
      // the stack top inside of the OR and make the OR the current top
      if( !check_syntax_only ) {
        unowned var last = _stack.last();
        if( (last != null) && ((last.data as FilterOr) == null) ) {
          var or_filter  = new FilterOr();
          var and_filter = new FilterAnd();
          var top_filter = last.data;
          _stack.remove( last.data );
          or_filter.add_filter( (FilterAnd)top_filter );
          _stack.append( or_filter );
          _stack.append( and_filter );
        }
      }
      return( true );
    }

    var parts = token.split( ":" );
    if( parts.length == 2 ) {
      var type_len  = parts[0].char_count();
      var new_start = (start_char + type_len + 1);
      var type_down = parts[0].down();
      if( type_down == _( "favorite" ) ) {
        return( parse_bool( "favorite", parts[1], new_start, check_syntax_only ) );
      } else if( type_down == _( "locked" ) ) {
        return( parse_bool( "locked", parts[1], new_start, check_syntax_only ) );
      } else if( type_down == _( "created" ) ) {
        return( parse_date( "created", parts[1], new_start, check_syntax_only ) );
      } else if( type_down == _( "updated" ) ) {
        return( parse_date( "updated", parts[1], new_start, check_syntax_only ) );
      } else if( type_down == _( "viewed" ) ) {
        return( parse_date( "viewed", parts[1], new_start, check_syntax_only ) );
      } else if( type_down == _( "notebook" ) ) {
        return( parse_notebook( parts[1], new_start, check_syntax_only ) );
      } else if( type_down == _( "tag" ) ) {
        return( parse_tag( parts[1], new_start, check_syntax_only ) );
      } else if( type_down == _( "title" ) ) {
        return( parse_text( "title", parts[1], new_start, check_syntax_only ) );
      } else if( type_down == _( "block" ) ) {
        return( parse_block( parts[1], new_start, check_syntax_only ) );
      } else if( type_down == _( "content" ) ) {
        return( parse_text( "content", parts[1], new_start, check_syntax_only ) );
      } else {
        _error_message = _( "Unknown token type (%s)" ).printf( parts[0].down() );
        _error_start   = start_char;
      }
    }

    if( parts.length == 1 ) {
      return( parse_text( "any", token, start_char, check_syntax_only ) );
    }

    return( false );

  }

  //-------------------------------------------------------------
  // Adds the given filter to the top of the stack
  private bool add_filter_to_stack_top( SmartFilter filter ) {
    unowned var last = _stack.last();
    if( last != null ) {
      var last_filter = (last.data as SmartLogicFilter);
      last_filter.add_filter( filter );
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Parses the tag string, creates the tag filter and adds it
  // to the top of the stack.
  //
  // Examples:
  //   tag:!foobar
  //   tag:barfoo
  private bool parse_tag( string tag, int start_char, bool check_syntax_only ) {
    stdout.printf( "parse_tag, tag: %s\n", tag );
    if( tag == "" ) {
      if( check_syntax_only ) {
        suggest( SmartParserSuggestion.TAG, start_char, "" );
      }
    } else if( tag.get_char( 0 ) == '!' ) {
      var rest = tag.substring( tag.index_of_nth_char( 1 ) );
      if( !check_syntax_only ) {
        var filter = new FilterTag( rest, FilterTagType.DOES_NOT_MATCH );
        add_filter_to_stack_top( filter );
      } else {
        suggest( SmartParserSuggestion.TAG_ONLY, (start_char + 1), rest );
      }
    } else {
      stdout.printf( "HERE!\n" );
      if( !check_syntax_only ) {
        var filter = new FilterTag( tag, FilterTagType.MATCHES );
        add_filter_to_stack_top( filter );
      } else {
        stdout.printf( "HERE!!!\n" );
        suggest( SmartParserSuggestion.TAG_ONLY, start_char, tag );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Parses the date value.
  //
  // Examples:
  //   created:is[YYYY/MM/DD]
  //   created:!YYYY/MM/DD  (same as is)
  //   created:between[YYYY/MM/DD-YYYY/MM/DD]
  //   created:YYYY/MM/DD-YYYY/MM/DD
  //   created:before[YYYY/MM/DD]
  //   created:<YYYY/MM/DD  (same as before)
  //   created:after[YYYY/MM/DD]
  //   created:>YYYY/MM/DD  (same as after)
  //   created:last[3days]
  //   created:!last[1y]
  private bool parse_date( string filter_type, string date, int start_char, bool check_syntax_only ) {
    var str = date;
    var not = false;
    if( str == "" ) {
      suggest( SmartParserSuggestion.DATE, start_char, "" );
    } else if( str.get_char( 0 ) == '!' ) {
      not = true;
      str = str.substring( str.index_of_nth_char( 1 ) );
    }
    if( str.has_suffix( "]" ) ) {
      str = str.slice( 0, str.index_of_nth_char( str.char_count() - 1 ) );
      if( str.has_prefix( _( "is[" ) ) ) {
        var len = _( "is[" ).char_count();
        var new_start = start_char + (not ? 1 : 0) + len;
        str = str.substring( str.index_of_nth_char( len ) );
        return( parse_absolute_date( filter_type, (not ? DateMatchType.IS_NOT : DateMatchType.IS), str, null, new_start, check_syntax_only ) );
      } else if( str.has_prefix( _( "between[" ) ) ) {
        var len = _( "between[" ).char_count();
        var new_start = start_char + (not ? 1 : 0) + len;
        str = str.substring( str.index_of_nth_char( len ) );
        var dates = str.split( "-" );
        if( dates.length == 2 ) {
          return( parse_absolute_date( filter_type, DateMatchType.BETWEEN, dates[0], dates[1], new_start, check_syntax_only ) );
        } else {
          _error_message = _( "Two dates must be specified" );
          _error_start   = new_start;
        }
      } else if( date.has_prefix( _( "before[" ) ) ) {
        var len = _( "before[" ).char_count();
        var new_start = start_char + (not ? 1 : 0) + len;
        str = str.substring( str.index_of_nth_char( len ) );
        return( parse_absolute_date( filter_type, DateMatchType.BEFORE, str, null, new_start, check_syntax_only ) );
      } else if( date.has_prefix( _( "after[" ) ) ) {
        var len = _( "after[" ).char_count();
        var new_start = start_char + (not ? 1 : 0) + len; 
        str = str.substring( str.index_of_nth_char( len ) );
        return( parse_absolute_date( filter_type, DateMatchType.AFTER, str, null, new_start, check_syntax_only ) );
      } else if( date.has_prefix( _( "last[" ) ) ) {
        var len = _( "last[" ).char_count();
        var new_start = start_char + (not ? 1 : 0) + len;
        str = str.substring( str.index_of_nth_char( len ) );
        return( parse_relative_date( filter_type, (not ? DateMatchType.LAST_NOT : DateMatchType.LAST), str, new_start, check_syntax_only ) );
      } else {
        _error_message = _( "Unknown date comparator" );
        _error_start   = (start_char + (not ? 1 : 0));
      }
    } else if( date.has_prefix( "<" ) ) {
      var new_start = start_char + (not ? 1 : 0) + 1;
      str = str.substring( str.index_of_nth_char( 1 ) );
      return( parse_absolute_date( filter_type, DateMatchType.BEFORE, str, null, new_start, check_syntax_only ) );
    } else if( date.has_prefix( ">" ) ) {
      var new_start = start_char + (not ? 1 : 0) + 1;
      return( parse_absolute_date( filter_type, DateMatchType.AFTER, str, null, new_start, check_syntax_only ) );
    } else {
      var dates = str.split( "-" );
      var new_start = start_char + (not ? 1 : 0);
      switch( dates.length ) {
        case 1 :
          return( parse_absolute_date( filter_type, (not ? DateMatchType.IS_NOT : DateMatchType.IS), str, null, new_start, check_syntax_only ) );
        case 2 :
          return( parse_absolute_date( filter_type, DateMatchType.BETWEEN, dates[0], dates[1], new_start, check_syntax_only ) );
        default :
          _error_message = _( "Only one or two dates are allowed" );
          _error_start   = new_start;
          break;
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Parses a string in the form of YYYY/MM/DD.  Returns the
  // associated DateTime structure if the string can be parsed;
  // otherwise, returns null to indicate that the date string
  // is invalid.
  private DateTime? parse_absolute_date_format( string? date, int start_char ) {
    if( date != null ) {
      var parts = date.split( "/" );
      if( (parts.length == 3) && (parts[0].length == 4) && (parts[1].length == 2) && (parts[2].length == 2) ) {
        var year  = int.parse( parts[0] );
        var month = int.parse( parts[1] );
        var day   = int.parse( parts[2] );
        if( (year != 0) && (month != 0) && (day != 0) ) {
          var dt = new DateTime.local( year, month, day, 0, 0, 0.0 );
          return( dt );
        }
      }
      _error_message = _( "Illegal date specified.  Must be YYYY/MM/DD" );
      _error_start   = start_char;
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Handle a date that should be treated as an absolute date.  We
  // will create and add up the filter(s) to the stack.
  private bool parse_absolute_date( string filter_type, DateMatchType match_type, string first, string? second, int start_char, bool check_syntax_only ) {
    if( first == "" ) {
      if( check_syntax_only ) {
        suggest( SmartParserSuggestion.DATE_ABS, start_char, "" );
      }
    } else if( (second != null) && (second == "") ) {
      if( check_syntax_only ) {
        suggest( SmartParserSuggestion.DATE_ABS, (start_char + first.char_count() + 1), "" );
      }
    }
    SmartDateFilter? filter = null;
    var first_date  = parse_absolute_date_format( first, start_char );
    var second_date = parse_absolute_date_format( second, (start_char + first.char_count() + 1) );
    if( (match_type == DateMatchType.BETWEEN) && (second_date == null) ) {
      return( false );
    }
    if( first_date != null ) {
      if( !check_syntax_only ) {
        switch( filter_type ) {
          case "created" :  filter = new FilterCreated.absolute( match_type, first_date, second_date );  break;
          case "updated" :  filter = new FilterUpdated.absolute( match_type, first_date, second_date );  break;
          case "viewed"  :  filter = new FilterViewed.absolute( match_type, first_date, second_date );   break;
        }
      }
      if( filter != null ) {
        add_filter_to_stack_top( filter );
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Handle a date that should be treated as a relative date to
  // the current date.  We will create and add up the filter(s)
  // to the stack.
  private bool parse_relative_date( string filter_type, DateMatchType match_type, string period, int start_char, bool check_syntax_only ) {
    if( period == "" ) {
      if( check_syntax_only ) {
        suggest( SmartParserSuggestion.DATE_REL, start_char, "" );
      }
    }
    SmartDateFilter? filter    = null;
    TimeType?        time_type = null;
    var num = -1;
    var str = "";
    period.down().scanf( "%d%s", &num, str );
    if( str != "" ) {
      time_type = TimeType.parse_full( str );
    }
    if( (num > 0) && (time_type != null) ) {
      if( !check_syntax_only ) {
        switch( filter_type ) {
          case "created" :  filter = new FilterCreated.relative( match_type, num, time_type );  break;
          case "updated" :  filter = new FilterUpdated.relative( match_type, num, time_type );  break;
          case "viewed"  :  filter = new FilterViewed.relative( match_type, num, time_type );   break;
        }
      }
      if( filter != null ) {
        add_filter_to_stack_top( filter );
        return( true );
      }
    } else {
      _error_message = _( "Unknown relative date specified.  Must be <num><time_period>." );
      _error_start   = start_char;
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Parses a boolean value.
  //
  // Examples:
  //   favorite:(true|false|0|1)
  private bool parse_bool( string filter_type, string rest, int start_char, bool check_syntax_only ) {
    var val = true;
    if( rest == "" ) {
      if( check_syntax_only ) {
        suggest( SmartParserSuggestion.BOOLEAN, start_char, "" );
      }
    } else if( (rest.down() == _( "true" )) || (rest == "1") ) {
      val = true;
    } else if( (rest.down() == _( "false" )) || (rest == "0") ) {
      val = false;
    } else {
      if( check_syntax_only ) {
        suggest( SmartParserSuggestion.BOOLEAN, start_char, rest );
      }
      _error_message = _( "Unknown boolean value specified (%s)" ).printf( rest );
      _error_start   = start_char;
      return( false );
    }
    if( !check_syntax_only ) {
      SmartFilter? filter = null;
      switch( filter_type ) {
        case "favorite" :  filter = new FilterFavorite( val );  break;
        case "locked"   :  filter = new FilterLocked( val );    break;
      }
      if( filter != null ) {
        add_filter_to_stack_top( filter );
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Parses the given notebook string value.
  //
  // Examples:
  //   notebook:<name>
  //   notebook:<path>/<of>/<notebook>
  private bool parse_notebook( string name, int start_char, bool check_syntax_only ) {
    if( check_syntax_only ) {
      suggest( SmartParserSuggestion.NOTEBOOK, start_char, name );
    } else {
      Notebook? nb = null;
      if( name == "" ) {
      } else if( name.contains( "/" ) ) {
        nb = _notebooks.find_notebook_by_path( name );
      } else {
        nb = _notebooks.find_notebook_by_name( name );
      }
      if( nb != null ) {
        var filter = new FilterNotebook( nb.id );
        add_filter_to_stack_top( filter );
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Parses the given title and creates a filter for it.
  //
  // Examples:
  //   title:<string>
  //   title:re[<string>]
  private bool parse_text( string filter_type, string text, int start_char, bool check_syntax_only ) {
    SmartFilter? filter = null;
    var pattern    = text;
    var match_type = TextMatchType.CONTAINS;
    if( text == "" ) {
      if( check_syntax_only ) {
        suggest( SmartParserSuggestion.TEXT, start_char, "" );
      }
    } else if( text.has_prefix( "re[" ) && text.has_suffix( "]" ) ) {
      pattern    = text.slice( text.index_of_nth_char( 3 ), text.index_of_nth_char( text.char_count() - 1 ) );
      match_type = TextMatchType.REGEXP;
    }
    if( !check_syntax_only ) {
      switch( filter_type ) {
        case "title"   :  filter = new FilterTitle( match_type, pattern );     break;
        case "content" :  filter = new FilterItemText( NoteItemType.MARKDOWN, match_type, pattern );  break;
        case "any"     :
          {
            var title_filter   = new FilterTitle( match_type, pattern );
            var content_filter = new FilterItemText( NoteItemType.MARKDOWN, match_type, pattern );
            var or_filter = new FilterOr();
            or_filter.add_filter( title_filter );
            or_filter.add_filter( content_filter );
            filter = or_filter;
          }
          break;
      }
      if( filter_type != null ) {
        add_filter_to_stack_top( filter );
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Parses the give block type.
  //
  // Examples:
  //   block:(markdown|code|image|uml)
  //   block:!code
  private bool parse_block( string block, int start_char, bool check_syntax_only ) {
    if( block == "" ) {
      if( check_syntax_only ) {
        suggest( SmartParserSuggestion.BLOCK, start_char, "" );
      }
    } else if( block.has_prefix( "!" ) ) {
      var name = block.substring( block.index_of_nth_char( 1 ) );
      var item_type = NoteItemType.parse( name );
      if( item_type != NoteItemType.NUM ) {
        if( !check_syntax_only ) {
          var item_filter = new FilterItem( item_type );
          var not_filter  = new FilterNot();
          not_filter.add_filter( item_filter );
          add_filter_to_stack_top( not_filter );
        }
        return( true );
      } else if( check_syntax_only ) {
        suggest( SmartParserSuggestion.BLOCK_ONLY, (start_char + 1), name );
      }
    } else {
      var item_type = NoteItemType.parse( block );
      if( item_type != NoteItemType.NUM ) {
        if( !check_syntax_only ) {
          var filter = new FilterItem( item_type );
          add_filter_to_stack_top( filter );
        }
        return( true );
      } else {
        suggest( SmartParserSuggestion.BLOCK_ONLY, start_char, block );
      }
    }
    _error_message = _( "Unknown note block type specified" );
    _error_start   = (start_char + (block.has_prefix( "!" ) ? 1 : 0));
    return( false );
  }

}