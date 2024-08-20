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

public class NoteParser {

  private Regex _image_re;
  private Regex _check_re;
  private Regex _title_re;
  private Regex _tag_block_re;
  private Regex _tag_list_re;

  //-------------------------------------------------------------
  // Default constructor
  public NoteParser() {
    try {
      _image_re     = new Regex( """^!\[(.*?)\]\s*\((.*?)\)$""" );
      _check_re     = new Regex( """^\[[ xX]?\]$""" );
      _title_re     = new Regex( """^title\s*:\s*(.*)$""" );
      _tag_block_re = new Regex( """^tags\s*:\s*\[(.*?)\]$""" ); 
      _tag_list_re  = new Regex( """^tags\s*:$""" );
    } catch( RegexError e ) {}
  }

  //-------------------------------------------------------------
  // Default constructor
  public Note parse_markdown( Notebook notebook, string markdown ) {

    var first   = true;
    var index   = 0;
    var start_index = 0;
    var in_yaml = false;
    var lines   = markdown.split( "\n" );
    var note    = new Note( notebook );

    foreach( var line in lines ) {
      var stripped = line.strip();
      if( stripped != "" ) {
        if( stripped == "---" ) {
          if( in_yaml ) {
            parse_yaml( note, lines[start_index:index] );
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
        note.title = dequote( match.fetch( 1 ) );
      } else if( _tag_block_re.match( stripped, 0, out match ) ) {
        parse_yaml_tag_block( note, match.fetch( 1 ) );
      } else if( _tag_list_re.match( stripped, 0, out match ) ) {
        in_tags = true;
      } else if( in_tags && line.has_prefix( "-" ) ) {
        var tag = line.substring( line.index_of_nth_char( 1 ) );
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
      return( stripped.slice( stripped.index_of_nth_char( 1 ), stripped.index_of_nth_char( stripped.char_count() - 1 ) ) );
    }
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

    stdout.printf( "code num lines: %u\n", lines.length );

    foreach( var line in lines ) {
      var stripped = line.strip();
      stdout.printf( "%d code line: (%s)\n", index, stripped );
      if( stripped.has_prefix( "```" ) ) {
        stdout.printf( "  Found code block!" );
        if( in_code_block ) {
          var code_item = new NoteItemCode( note ) {
            lang    = language,
            content = code
          };
          note.add_note_item( note.size(), code_item );
          language = "";
          code     = "";
          start_index = index + 1;
          in_code_block = false;
        } else {
          if( start_index != index ) {
            parse_markdown_image( note, lines[start_index:index-1] );
          }
          language = stripped.substring( stripped.index_of_nth_char( 3 ) );
          in_code_block = true;
        }
      } else if( in_code_block ) {
        code += line + "\n";
      }
      index++;
    }

    if( start_index != index ) {
      parse_markdown_image( note, lines[start_index:index-1] );
    }

  }

  //-------------------------------------------------------------
  // Repairs the given URI if it is not valid.
  private string fix_uri( string uri ) {
    try {
      if( !Uri.is_valid( uri, UriFlags.PARSE_RELAXED ) ) {
        return( "file://" + uri );
      }
      return( uri );
    } catch( UriError e ) {
      return( "file://" + uri );
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
          parse_markdown_table( note, lines[start_index:index-1] );
        }
        var image_item = new NoteItemImage( note ) {
          uri = fix_uri( match.fetch( 2 ) ),
          description = match.fetch( 1 )
        };
        note.add_note_item( note.size(), image_item );
        start_index = index + 1;
      }
      index++;
    }

    if( start_index != index ) {
      parse_markdown_table( note, lines[start_index:index-1] );
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
        if( date.valid() ) {
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
          table_item = new NoteItemTable( note, (columns.length - 2) );
          parse_markdown_table_header( table_item, columns[1:columns.length-2] );
          in_header = false;
          in_align  = true;
        } else if( in_align ) {
          parse_markdown_table_align( table_item, columns[1:columns.length-2] );
          in_align     = false;
          in_first_row = true;
        } else if( in_first_row ) {
          parse_markdown_table_first_row( table_item, columns[1:columns.length-2] );
          parse_markdown_table_row( table_item, columns[1:columns.length-2] );
          in_first_row = false;
        } else {
          parse_markdown_table_row( table_item, columns[1:columns.length-2] );
        }
        start_index = index + 1;
      } else if( table_item != null ) {
        note.add_note_item( note.size(), table_item );
        table_item  = null;
        in_header   = true;
        start_index = index;
      }
      index++;
    }

    if( start_index != index ) {
      parse_markdown_markdown( note, lines[start_index:index] );
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
    var text = string.joinv( "\n", lines ).strip();
    if( text != "" ) {
      var markdown_item = new NoteItemMarkdown( note ) {
        content = string.joinv( "\n", lines ).strip()
      };
      note.add_note_item( note.size(), markdown_item );
    }
  }

}