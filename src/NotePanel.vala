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

using Gtk;

public class NotePanel : Box {

  private Note  _note;

  private Entry _title;
  private Box   _created_box;
  private Label _created;
  private Box   _content;

	// Default constructor
	public NotePanel() {

    Object(
      orientation: Orientation.VERTICAL,
      spacing: 5,
      margin_top: 5,
      margin_bottom: 5,
      margin_start: 5,
      margin_end: 5
    );

    var created_lbl = new Label( _( "Created:" ) );
    _created = new Label( "" );
    _created_box = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.END,
      hexpand = true,
      visible = false
    };
    _created_box.append( created_lbl );
    _created_box.append( _created );

    var hbox = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.FILL
    };
    hbox.append( _created_box );

    _title = new Entry() {
      has_frame = false,
      placeholder_text = _( "Title (Optional)" ),
      halign = Align.FILL
    };

    var separator = new Separator( Orientation.HORIZONTAL );

    _content = new Box( Orientation.VERTICAL, 0 ) {
      halign = Align.FILL,
      valign = Align.FILL,
      vexpand = true
    };

    var sw = new ScrolledWindow() {
      halign = Align.FILL,
      valign = Align.FILL,
      hscrollbar_policy = PolicyType.NEVER,
      vscrollbar_policy = PolicyType.AUTOMATIC,
      child = _content
    };

    // Add an initial markdown item
    add_markdown_item( null );

    append( hbox );
    append( _title );
    append( separator );
    append( sw );

	}

  public void populate_with_note( Note? note ) {

    _note = note;

    if( _note != null ) {
      _created_box.visible = true;
      _created.label = note.created.to_string(); 
      _title.text    = note.title;
    } else {
      _created_box.visible = false;
      _title.text = "";
    }

    populate_content();

  }

  private void populate_content() {

    Utils.clear_box( _content );

    if( _note != null ) {
      for( int i=0; i<_note.size(); i++ ) {
        var item = _note.get_item( i ); 
        switch( item.name ) {
          case "markdown" :  add_markdown_item( (NoteItemMarkdown)item );  break;
          case "code"     :  add_code_item( (NoteItemCode)item );          break;
          case "image"    :  add_image_item( (NoteItemImage)item );        break;
          default         :  assert_not_reached();
        }
      }
    } else {
      add_markdown_item( null );
    }

  }

  private void add_markdown_item( NoteItemMarkdown? item ) {

    var lang_mgr = new GtkSource.LanguageManager();
    var lang     = lang_mgr.get_language( "markdown" );

    var buffer   = new GtkSource.Buffer.with_language( lang ) {
      highlight_syntax = true,
      enable_undo      = true,
      text             = (item == null) ? "" : item.content
    };

    var focus = new EventControllerFocus();
    var text = new GtkSource.View.with_buffer( buffer ) {
      halign    = Align.FILL,
      valign    = Align.FILL,
      vexpand   = true,
      wrap_mode = WrapMode.WORD,
      editable  = true
    };
    text.add_controller( focus );

    focus.enter.connect(() => {
      // Make the UI display Markdown toolbar
    });

    focus.leave.connect(() => {
      if( item != null ) {
        item.content = buffer.text;
      }
    });

    _content.append( text );

  }

  private void add_code_item( NoteItemCode item ) {

  }

  private void add_image_item( NoteItemImage item ) {

  }

}