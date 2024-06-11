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

public class NoteItemPaneUML : NoteItemPane {

  private GtkSource.View _text;
  private Picture        _image;
  private Stack          _stack;

	// Default constructor
	public NoteItemPaneUML( MainWindow win, NoteItem item, SpellChecker spell ) {
    base( win, item, spell );
  }

  public override GtkSource.View? get_text() {
    if( _stack.visible_child_name == "input" ) {
      return( _text );
    }
    return( null );
  }

  // Grabs the focus of the note item at the specified position.
  public override void grab_item_focus( TextCursorPlacement placement ) {
    if( _stack.visible_child_name == "input" ) {
      place_cursor( _text, placement );
      _text.grab_focus();
    } else {
      _image.grab_focus();
    }
  }

  // Adds a new UML item at the given position in the content area
  protected override void create_pane() {

    var uml_item = (NoteItemUML)item;

    var image_click = new GestureClick();
    var image_focus = new EventControllerFocus();
    _image = new Picture() {
      halign = Align.FILL,
      valign = Align.FILL,
      margin_start  = 5,
      margin_end    = 5,
      margin_start  = 5,
      margin_bottom = 5,
      focusable     = true
    };
    _image.add_controller( image_click );
    _image.add_controller( image_focus );

    var label = new Label( _( "UML Diagram Input" ) ) {
      halign  = Align.START,
      hexpand = true
    };
    var help = new Button.with_label( _( "UML Syntax" ) ) {
      halign = Align.END
    };
    help.clicked.connect(() => {
      Utils.open_url( "https://plantuml.com/" );
    });
    var show = new Button.with_label( _( "Show Diagram" ) ) {
      halign = Align.END
    };

    var hbox = new Box( Orientation.HORIZONTAL, 5 );
    hbox.append( label );
    hbox.append( help );
    hbox.append( show );

    _text = create_text( "plantuml" );
    var buffer = (GtkSource.Buffer)_text.buffer;

    _text.add_css_class( "code-text" );

    var tbox = new Box( Orientation.VERTICAL, 5 );
    tbox.append( hbox );
    tbox.append( _text );

    var loading = new Label( _( "Generating Diagram..." ) ) {
      halign = Align.CENTER,
      valign = Align.CENTER
    };
    loading.add_css_class( "note-title" );

    _stack = new Stack();
    _stack.add_named( tbox,    "input" );
    _stack.add_named( loading, "loading" );
    _stack.add_named( _image,  "image" );

    show.clicked.connect(() => {
      if( item.content == buffer.text ) {
        _stack.visible_child_name = "image";
      } else {
        _stack.visible_child_name = "loading";
        uml_item.content = buffer.text;
      }
    });

    uml_item.diagram_updated.connect((filename) => {
      if( filename != null ) {
        _image.file = File.new_for_path( filename );
        _stack.visible_child_name = "image";
      } else {
        _stack.visible_child_name = "input";
      }
    });

    image_click.pressed.connect((n_press, x, y) => {
      if( n_press == 1 ) {
        _image.grab_focus();
      } else if( n_press == 2 ) {
        set_as_current();
        _stack.visible_child_name = "input";
        _text.grab_focus();
      }
    });

    image_focus.enter.connect(() => {
      set_as_current();
      add_css_class( "active-item" );
    });

    image_focus.leave.connect(() => {
      remove_css_class( "active-item" );
    });

    // Load the image and make it visible (if it exists); otherwise, display the input field.
    if( FileUtils.test( uml_item.get_resource_filename(), FileTest.EXISTS ) ) {
      _image.file = File.new_for_path( uml_item.get_resource_filename() );
      _stack.visible_child_name = "image";
    } else {
      _stack.visible_child_name = "input";
    }

    handle_key_events( _text );
    handle_key_events( _image );

    append( _stack );

  }

}