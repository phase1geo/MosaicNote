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

public class GalleryItem : Box {

  private MainWindow _win;
  private NoteItem   _item;
  private Stack      _stack;

  private const GLib.ActionEntry[] action_entries = {
    { "action_view_note",   action_view_note },
    { "action_copy_pane",   action_copy_pane, "i" },
    { "action_export_pane", action_export_pane, "i" },
  };

  public MainWindow win {
    get {
      return( _win );
    }
  }

  public NoteItem item {
    get {
      return( _item );
    }
  }

  public signal void show_note( Note note );
  public signal void highlight_match( string pattern );

  //-------------------------------------------------------------
  // Default constructor
  public GalleryItem( MainWindow win, NoteItem item ) {

    Object( orientation: Orientation.VERTICAL, spacing: 5 );

    _win  = win;
    _item = item;

    _stack = new Stack() {
      valign  = Align.START,
      vexpand = true
    };

    append( create_bar() );
    append( _stack );

    populate_stack();

    /* Set the stage for menu actions */
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "gpane", actions );

  }

  //-------------------------------------------------------------
  // Creates the header bar that is displayed above the content.
  private Box create_bar() {

    var box = new Box( Orientation.HORIZONTAL, 5 );

    if( panes() > 1 ) {

      var flip = new Button.from_icon_name( "media-playlist-repeat-symbolic" ) {
        halign       = Align.START,
        has_frame    = false,
        tooltip_text = _( "Show %s" ).printf( pane_label( 1 ) )
      };

      flip.clicked.connect(() => {
        int next = (int.parse( _stack.visible_child_name.get_char( 4 ).to_string() ) + 1) % panes();
        flip.tooltip_text = _( "Show %s" ).printf( pane_label( (next + 1) % panes() ) );
        _stack.visible_child_name = "pane%d".printf( next );
      });

      box.append( flip );

    }

    var header = create_header();
    header.halign = Align.FILL;
    box.append( header );

    var view_menu = new GLib.Menu();
    view_menu.append( _( "View Note" ), "gpane.action_view_note" );

    var copy_menu = new GLib.Menu();
    for( int i=0; i<panes(); i++ ) {
      copy_menu.append( _( "Copy %s" ).printf( pane_label( i ) ), "gpane.action_copy_pane(%d)".printf( i ) );
    }

    var export_menu = new GLib.Menu();
    for( int i=0; i<ExportType.NUM; i++ ) {
      var etype = (ExportType)i;
      export_menu.append( etype.label(), "gpane.action_export_pane(%d)".printf( i ) );
    }
    var exp_menu = new GLib.Menu();
    exp_menu.append_submenu( _( "Export Item" ), export_menu );

    var menu = new GLib.Menu();
    menu.append_section( null, view_menu );
    menu.append_section( null, copy_menu );
    menu.append_section( null, exp_menu );

    var menu_button = new MenuButton() {
      halign     = Align.END,
      hexpand    = true,
      icon_name  = "view-more-horizontal-symbolic",
      has_frame  = false,
      always_show_arrow = false,
      menu_model = menu
    };

    box.append( menu_button );

    return( box );

  }

  //-------------------------------------------------------------
  // Populates the stack.
  private void populate_stack() {
    for( int i=0; i<panes(); i++ ) {
      var pane = create_pane( i );
      if( pane != null ) {
        _stack.add_named( pane, "pane%d".printf( i ) );
      }
    }
  }

  //-------------------------------------------------------------
  // Returns the number of panes that will be displayed
  protected virtual int panes() {
    return( 1 );
  }

  //-------------------------------------------------------------
  // Returns the 
  protected virtual string pane_label( int pane_index ) {
    return( _( "Content" ) );
  }

  //-------------------------------------------------------------
  // Adds line spacing
  private void set_line_spacing( GtkSource.View text ) {

    var wrap    = MosaicNote.settings.get_int( "editor-line-spacing" );
    var spacing = (item.item_type == NoteItemType.MARKDOWN) ? (wrap * 4) : wrap;
    var above   = ((spacing % 2) == 0) ? (spacing / 2) : ((spacing - 1) / 2);
    var below   = spacing - above;

    text.pixels_above_lines = above;
    text.pixels_below_lines = below;
    text.pixels_inside_wrap = wrap;

  }

  //-------------------------------------------------------------
  // Sets the height of the text widget
  private void set_text_height( GtkSource.View text ) {

    TextIter iter;
    Gdk.Rectangle location;

    text.buffer.get_start_iter( out iter );
    text.get_iter_location( iter, out location );
    text.set_size_request( -1, (location.height + 8) );

  }

  //-------------------------------------------------------------
  // Creates a text box with syntax highlighting enabled for the given
  // language ID.  Note item panes that contain a text widget should
  // call this function to create and configure the text widget that
  // can be embedded in the pane.
  protected Widget create_text_pane( string content, string? lang_id = null ) {

    var buffer = new GtkSource.Buffer( null ) {
      highlight_syntax = true,
      enable_undo      = false,
      text             = content
    };

    buffer.create_tag( "highlight", "background", "yellow", null );

    highlight_match.connect((pattern) => {

      TextIter start, end;

      // Clear highlights
      buffer.get_start_iter( out start );
      buffer.get_end_iter( out end );
      buffer.remove_tag_by_name( "highlight", start, end );

      // Add highlight if we get a match
      var str        = buffer.text;
      var start_byte = str.index_of( pattern );
      if( start_byte != -1 ) {
        var start_pos = str.slice( 0, start_byte ).char_count();
        buffer.get_iter_at_offset( out start, start_pos );
        buffer.get_iter_at_offset( out end,   (start_pos + pattern.char_count()) );
        buffer.apply_tag_by_name( "highlight", start, end );
      }

    });

    if( lang_id != null ) {
      var lang_mgr = GtkSource.LanguageManager.get_default();
      var lang     = lang_mgr.get_language( lang_id );
      buffer.set_language( lang );
    }

    var text = new GtkSource.View.with_buffer( buffer ) {
      halign        = Align.FILL,
      valign        = Align.FILL,
      vexpand       = true,
      editable      = false,
      margin_top    = 5,
      margin_bottom = 5,
      margin_start  = 5,
      margin_end    = 5
    };

    item.item_type.initialize_text( text );

    set_line_spacing( text );
    set_text_height( text );

    MosaicNote.settings.changed["editor-line-spacing"].connect(() => {
      set_line_spacing( text );
    });

    var style_mgr = new GtkSource.StyleSchemeManager();
    buffer.style_scheme = style_mgr.get_scheme( win.themes.get_current_theme() );
    win.themes.theme_changed.connect((theme) => {
      buffer.style_scheme = style_mgr.get_scheme( theme );
    });

    var sw = new ScrolledWindow() {
      hscrollbar_policy = PolicyType.AUTOMATIC,
      vscrollbar_policy = PolicyType.AUTOMATIC,
      min_content_height = 300,
      max_content_height = 300,
      child = text
    };

    return( sw );

  }

  //-------------------------------------------------------------
  // Adds the UI for the image panel.
  protected Widget create_image_pane( string filename ) {

    var image_drag = new DragSource() {
      actions = Gdk.DragAction.COPY
    };

    var image = new Picture() {
      halign        = Align.FILL,
      valign        = Align.FILL,
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5,
      file          = File.new_for_path( filename )
    };

    image.add_controller( image_drag );

    image_drag.prepare.connect((d) => {
      var val = Value( typeof(GLib.File) );
      val = image.file;
      var cp = new Gdk.ContentProvider.for_value( val );
      return( cp );
    });

    return( image );

  }

  //-------------------------------------------------------------
  // Highlights a given label if its label contains the given string.
  protected void highlight_label( Label label, string str, string pattern ) {
    var start  = str.index_of( pattern );
    var markup = str;
    if( start != -1 ) {
      var end    = pattern.length + start;
      var first  = str.slice( 0, start );
      var middle = str.slice( start, end );
      var last   = str.substring( end );
      markup = first + "<span background='yellow'>" + middle + "</span>" + last;
    }
    label.label = Utils.make_title( markup );
  }

  //-------------------------------------------------------------
  // Highlights text that matches the specified pattern.
  protected void highlight_text( TextView text, string pattern ) {

    var str = text.buffer.text;

  }

  //-------------------------------------------------------------
  // Generates the header that will be displayed above the pane.
  protected virtual Widget create_header() {

    var label = new Label( "" ) {
      halign = Align.FILL
    };

    return( label );

  }

  //-------------------------------------------------------------
  // Generates the main pain displaying the content.
  protected virtual Widget? create_pane( int pane ) {
    return( null );
  }

  //-------------------------------------------------------------
  // Copies the given pane content to the clipboard.
  protected virtual void copy_pane_to_clipboard( int pane_index ) {}

  //-------------------------------------------------------------
  // Copies the given text to the clipboard
  protected void copy_text_to_clipboard( string text ) {
    var clipboard = Gdk.Display.get_default().get_clipboard();
    clipboard.set_text( text );
  }

  //-------------------------------------------------------------
  // Copies the given picture image to the clipboard
  protected void copy_image_to_clipboard( string filename ) {
    try {
      var clipboard = Gdk.Display.get_default().get_clipboard();
      var texture   = Gdk.Texture.from_filename( filename );
      clipboard.set_texture( texture );
    } catch( Error e ) {}
  }

  //-------------------------------------------------------------
  // Displays the note associated with this item.
  private void action_view_note() {
    var note = item.note;
    show_note( note );
  }

  //-------------------------------------------------------------
  // Copies the specified pane to the clipboard.
  private void action_copy_pane( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var pane_index = variant.get_int32();
      copy_pane_to_clipboard( pane_index );
    }
  }

  //-------------------------------------------------------------
  // Exports the specified pane to the clipboard.
  private void action_export_pane( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var etype = (ExportType)variant.get_int32();
      Export.export_note_item( _win, etype, item );
    }
  }

}