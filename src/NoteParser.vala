/*
* Copyright (c) 2024-2026 (https://github.com/phase1geo/MosaicNote)
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

public class NoteParser {

  private Regex _image_re;
  private Regex _check_re;
  private Regex _title_re;
  private Regex _created_re;
  private Regex _updated_re;
  private Regex _tag_block_re;
  private Regex _tag_list_re;

  //-------------------------------------------------------------
  // Default constructor
  public NoteParser() {
    try {
      _image_re     = new Regex( """^!\[(.*?)\]\s*\((.*?)\)$""" );
      _check_re     = new Regex( """^\[[ xX]?\]$""" );
      _title_re     = new Regex( """^title\s*:\s*(.*)$""" );
      _created_re   = new Regex( """^created\s*:\s*(.*)$""" );
      _updated_re   = new Regex( """^updated\s*:\s*(.*)$""" );
      _tag_block_re = new Regex( """^tags\s*:\s*\[(.*?)\]$""" ); 
      _tag_list_re  = new Regex( """^tags\s*:$""" );
    } catch( RegexError e ) {}
  }

  //-------------------------------------------------------------
  // Default constructor
  public Note parse_markdown( Notebook notebook, string markdown, bool include_front_matter ) {

    var first   = true;
    var index   = 0;
    var start_index = 0;
    var in_yaml = false;
    var lines   = markdown.split( "\n" );
    var note    = new Note( notebook, false );

    foreach( var line in lines ) {
      var stripped = line.strip();
      if( stripped != "" ) {
        if( stripped == "---" ) {
          if( in_yaml ) {
            if( include_front_matter ) {
              parse_yaml( note, lines[start_index:index] );
            }
            parse_markdown_code( note, lines[index+1:lines.length] );
            break;
          } else if( first ) {
            start_index = index + 1;
            in_yaml = true;
          }
        }
        first = false;
      }
      index++;
    }

    // If we didn't find any front matter, parse the remaining text as Markdown
    if( !in_yaml ) {
      parse_markdown_code( note, lines );
    }

    return( note );

  }

  //-------------------------------------------------------------
  // Parses the frontend matter with the Yaml parser
  private void parse_yaml( Note note, string[] lines ) {

    MatchInfo match;

    var index   = 0;
    var in_tags = false;

    foreach( var line in lines ) {
      var stripped = line.strip();
      if( _title_re.match( stripped, 0, out match ) ) {
        note.initialize_title( dequote( match.fetch( 1 ) ) );
      } else if( _created_re.match( stripped, 0, out match ) ) {
        var created = new DateTime.from_iso8601( dequote( match.fetch( 1 ) ), null );
        note.initialize_created( created );
      } else if( _updated_re.match( stripped, 0, out match ) ) {
        var updated = new DateTime.from_iso8601( dequote( match.fetch( 1 ) ), null );
        note.initialize_updated( updated );
      } else if( _tag_block_re.match( stripped, 0, out match ) ) {
        parse_yaml_tag_block( note, match.fetch( 1 ) );
      } else if( _tag_list_re.match( stripped, 0, out match ) ) {
        in_tags = true;
      } else if( in_tags && stripped.has_prefix( "-" ) ) {
        var tag = stripped.substring( stripped.index_of_nth_char( 1 ) );
        note.tags.add_tag( dequote( tag.strip() ) );
      } else {
        in_tags = false;
      }
      index++;
    }

  }

  //-------------------------------------------------------------
  // Removes double-quotes from the given string (if it exists).
  private string dequote( string str ) {
    var stripped = str.strip();
    if( (stripped.has_prefix( "\"" ) && stripped.has_suffix( "\"" )) ||
        (stripped.has_prefix( "'" )  && stripped.has_suffix( "'" )) ) {
      stripped = stripped.slice( stripped.index_of_nth_char( 1 ), stripped.index_of_nth_char( stripped.char_count() - 1 ) );
    }
    stripped = stripped.replace( "''", "'" );
    stripped = stripped.replace( "\"\"", "\"" );
    return( stripped );
  }

  //-------------------------------------------------------------
  // Parses the YAML tag block list.
  private void parse_yaml_tag_block( Note note, string content ) {
    var tags = content.split( "," );
    foreach( var tag in tags ) {
      note.tags.add_tag( dequote( tag ) );
    }
  }

  //-------------------------------------------------------------
  // Parses the given lines for Markdown code blocks.
  private void parse_markdown_code( Note note, string[] lines ) {

    var in_code_block = false;
    var code          = "";
    var language      = "";
    var index         = 0;
    var start_index   = 0;

    foreach( var line in lines ) {
      var stripped = line.strip();
      if( stripped.has_prefix( "```" ) ) {
        if( in_code_block ) {
          var row = new NoteItemRow( note );
          var code_item = new NoteItemCode( row ) {
            lang    = language,
            content = code.strip()
          };
          row.add_item( code_item );
          note.add_row( row );
          language = "";
          code     = "";
          start_index = index + 1;
          in_code_block = false;
        } else {
          if( start_index != index ) {
            parse_markdown_image( note, lines[start_index:index] );
          }
          var lang_start = stripped.index_of_nth_char( 3 );
          if( lang_start < stripped.length ) {
            language = stripped.substring( lang_start ).down();
          }
          in_code_block = true;
        }
      } else if( in_code_block ) {
        code += line + "\n";
      }
      index++;
    }

    if( start_index != index ) {
      parse_markdown_image( note, lines[start_index:index] );
    }

  }

  //-------------------------------------------------------------
  // Repairs the given URI if it is not valid.
  private string fix_uri( string uri ) {
    var parts = uri.split( " " );
    try {
      if( !Uri.is_valid( parts[0], UriFlags.PARSE_RELAXED ) ) {
        return( "file://" + parts[0] );
      }
      return( parts[0] );
    } catch( UriError e ) {
      return( "file://" + parts[0] );
    }
  }

  //-------------------------------------------------------------
  // Parses the given lines for images specified on their own line.
  private void parse_markdown_image( Note note, string[] lines ) {

    MatchInfo match;
    var index = 0;
    var start_index = 0;

    foreach( var line in lines ) {
      var stripped = line.strip();
      if( _image_re.match( stripped, 0, out match ) ) {
        if( start_index != index ) {
          parse_markdown_table( note, lines[start_index:index] );
        }
        var row = new NoteItemRow( note );
        var fixed_uri = fix_uri( match.fetch( 2 ) );
        var image_item = new NoteItemImage( row ) {
          uri = fixed_uri,
          description = match.fetch( 1 )
        };
        row.add_item( image_item );
        note.add_row( row );
        start_index = index + 1;
      }
      index++;
    }

    if( start_index != index ) {
      parse_markdown_table( note, lines[start_index:index] );
    }

  }

  //-------------------------------------------------------------
  // Parses the Markdown table header row.
  private void parse_markdown_table_header( NoteItemTable item, string[] columns ) {
    var index = 0;
    foreach( var col in columns ) {
      var stripped = col.strip();
      var column   = item.get_column( index );
      column.header = stripped;
      index++;
    }
  }

  //-------------------------------------------------------------
  // Parses the Markdown table alignment row.
  private void parse_markdown_table_align( NoteItemTable item, string[] columns ) {
    var index = 0;
    foreach( var col in columns ) {
      var stripped = col.strip();
      var column   = item.get_column( index );
      if( stripped.has_prefix( ":" ) ) {
        if( stripped.has_suffix( ":" ) ) {
          column.justify = Gtk.Justification.CENTER;
        } else {
          column.justify = Gtk.Justification.LEFT;
        }
      } else {
        if( stripped.has_suffix( ":" ) ) {
          column.justify = Gtk.Justification.RIGHT;
        } else {
          column.justify = Gtk.Justification.LEFT;
        }
      }
      index++;
    }
  }

  //-------------------------------------------------------------
  // Checks to see if the given string is a number.
  private bool is_number( string text ) {
    double value;
    return( double.try_parse( text, out value ) );
  }

  //-------------------------------------------------------------
  // Parses the data in the first row to figure out what type of
  // data is being stored in each column
  private void parse_markdown_table_first_row( NoteItemTable item, string[] columns ) {

    Date date = {};
    var index = 0;

    foreach( var col in columns ) {
      MatchInfo match;
      var stripped = col.strip();
      var column   = item.get_column( index );
      if( _check_re.match( stripped, 0, out match ) ) {
        column.data_type = TableColumnType.CHECKBOX; 
      } else {
        date.set_parse( stripped );
        if( date.valid() && !is_number( stripped ) ) {
          column.data_type = TableColumnType.DATE;
        } else {
          column.data_type = TableColumnType.TEXT;
        }
      }
      index++;
    }
  }

  //-------------------------------------------------------------
  // Parses the given table row.
  private void parse_markdown_table_row( NoteItemTable item, string[] columns ) {
    var col_index = 0;
    var row_index = item.rows();
    item.insert_row( row_index );
    foreach( var col in columns ) {
      var val = item.get_column( col_index ).data_type.from_markdown( col.strip() );
      item.set_cell( col_index, row_index, val );
      col_index++;
    }
  }

  //-------------------------------------------------------------
  // Parses the given lines for Markdown tables.
  private void parse_markdown_table( Note note, string[] lines ) {

    NoteItemTable? table_item = null;
    NoteItemRow?   row = null;
    var index        = 0;
    var start_index  = 0;
    var in_header    = true;
    var in_align     = false;
    var in_first_row = false;

    foreach( var line in lines ) {
      var stripped = line.strip();
      if( stripped.has_prefix( "|" ) ) {
        if( (start_index != index) && (table_item == null) ) {
          parse_markdown_markdown( note, lines[start_index:index] );
        }
        var columns = stripped.split( "|" );
        if( in_header ) {
          row = new NoteItemRow( note );
          table_item = new NoteItemTable( row, (columns.length - 2) );
          parse_markdown_table_header( table_item, columns[1:columns.length-1] );
          in_header = false;
          in_align  = true;
        } else if( in_align ) {
          parse_markdown_table_align( table_item, columns[1:columns.length-1] );
          in_align     = false;
          in_first_row = true;
        } else if( in_first_row ) {
          parse_markdown_table_first_row( table_item, columns[1:columns.length-1] );
          parse_markdown_table_row( table_item, columns[1:columns.length-1] );
          in_first_row = false;
        } else {
          parse_markdown_table_row( table_item, columns[1:columns.length-1] );
        }
        start_index = index + 1;
      } else if( table_item != null ) {
        row.add_item( table_item );
        note.add_row( row );
        table_item  = null;
        in_header   = true;
        start_index = index;
      }
      index++;
    }

    if( table_item != null ) {
      row.add_item( table_item );
      note.add_row( row );
    }

    if( start_index != index ) {
      parse_markdown_markdown( note, lines[start_index:index] );
    }

  }

  //-------------------------------------------------------------
  // Join the lines and append resulting Markdown into a new
  // Markdown item in the specified note.
  private void add_markdown_item( Note note, string[] lines, bool force_add = false ) {
    var text = string.joinv( "\n", lines ).strip();
    if( (text != "") || force_add ) {
      var row = new NoteItemRow( note );
      var markdown_item = new NoteItemMarkdown( row ) {
        content = text
      };
      row.add_item( markdown_item );
      note.add_row( row );
    }
  }

  //-------------------------------------------------------------
  // Parses the given lines for normal Markdown content.  In this
  // case because we have parsed everything else out of the Markdown,
  // the given lines contain Markdown that can be put into a Markdown
  // item as it.  We will just join the lines array with new lines and
  // assign it to a new Markdown item content value and add the item
  // to the note.
  private void parse_markdown_markdown( Note note, string[] lines ) {

    string[] new_lines = {};

    try {
      MatchInfo matched;
      var fn_re = new Regex( """^\[\^(.*?)\]:\s*(.*)$""" );
      var sp_re = new Regex( """^ {4}(.*)$""" );
      var hr_re = new Regex( """^[ ]{0,3}((-[ ]{0,2}){3,}|(_[ ]{0,2}){3,}|(\*[ ]{0,2}){3,})[ \t]*$""" );
      var id    = "";
      var description = "";
      var in_footnote = false;
      var last = "";
      foreach( var line in lines ) {
        if( in_footnote ) {
          if( sp_re.match( line, 0, out matched ) ) {
            description += "\n%s".printf( matched.fetch( 1 ).strip() );
          } else {
            in_footnote = false;
            note.add_footnote( id, description );
          }
        }
        if( !in_footnote ) {
          if( fn_re.match( line, 0, out matched ) ) {
            id          = matched.fetch( 1 );
            description = matched.fetch( 2 );
            in_footnote = true;
          } else if( (last.strip() == "") && hr_re.match( line, 0 ) ) {
            add_markdown_item( note, new_lines, true );
            new_lines = {};
          } else {
            new_lines += line;
          }
        }
        last = line;
      }
      if( in_footnote ) {
        note.add_footnote( id, description );
      }
    } catch( RegexError e ) {}

    // Add the current lines
    add_markdown_item( note, new_lines );

  }

}
