/*
* Copyright (c) 2024-2026 (https://github.com/phase1geo/MosaicNote)
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
using Gee;

public class NoteItemPaneTable : NoteItemPane {

  private Label      _h2_label;
  private ColumnView _table;
  private int        _col_id = 0;
  private int        _row_id = 0;
  private HashMap<string, ListItem> _row_map;

  private const GLib.ActionEntry[] action_entries = {
    { "action_format_column",        action_format_column,        "s" },
    { "action_insert_column_before", action_insert_column_before, "s" },
    { "action_insert_column_after",  action_insert_column_after,  "s" },
    { "action_delete_column",        action_delete_column,        "s" },
    { "action_insert_row_above",     action_insert_row_above,     "s" },
    { "action_insert_row_below",     action_insert_row_below,     "s" },
    { "action_delete_row",           action_delete_row,           "s" },
  };

  private signal void auto_number_changed();
  public signal void column_title_changed( string id );
  public signal void column_type_changed( string id, TableColumnType old_type );
  public signal void column_justify_changed( string id );

  public NoteItemTable table_item {
    get {
      return( (NoteItemTable)item );
    }
  }

  //-------------------------------------------------------------
	// Default constructor
	public NoteItemPaneTable( MainWindow win, NoteItem item, SpellChecker spell ) {

    base( win, item, spell );

    _row_map = new HashMap<string, ListItem>();

    // Set the stage for menu actions
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "table", actions );

  }

  //-------------------------------------------------------------
  // Destructor
  ~NoteItemPaneTable() {
    if( MosaicNote.debug ) {
      stdout.printf( "NoteItemPaneTable destroyed\n" );
    }
  }

  //-------------------------------------------------------------
  // Removes all signal handlers prior to destruction.
  public override void cleanup() {

    // Disconnect global signals
    base.cleanup();

    // Remove action group
    insert_action_group( "table", null );

    // Force the rows to unbind
    _row_map.map_iterator().foreach((k, v) => {
      row_unbind( v );
      return( true );
    });
    _row_map.clear();

  }

  //-------------------------------------------------------------
  // Grabs the focus of the note item at the specified position.
  public override void grab_item_focus( TextCursorPlacement placement, int offset = 0 ) {
    _table.grab_focus();
  }

  //-------------------------------------------------------------
  // Adds the auto-number setting to the specified table settings
  // widgets.
  private void add_auto_number_setting( GLib.Menu menu, PopoverMenu popup_menu ) {

    var autonum_label = new Label( _( "Auto-number rows" ) ) {
      halign = Align.START,
      hexpand = true
    };

    var autonum_sw = new Switch() {
      halign = Align.END,
      active = table_item.auto_number
    };

    var active_id = autonum_sw.notify["active"].connect(() => {
      table_item.auto_number = autonum_sw.active;
      auto_number_changed();
    });
    add_signal( autonum_sw, active_id );

    var autonum_box = new Box( Orientation.HORIZONTAL, 5 ) {
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 5,
      margin_bottom = 5
    };
    autonum_box.append( autonum_label );
    autonum_box.append( autonum_sw );

    var autonum_mi = new MenuItem( null, null );
    autonum_mi.set_attribute( "custom", "s", "autonum" );

    menu.append_item( autonum_mi );
    popup_menu.add_child( autonum_box, "autonum" );

  }

  //-------------------------------------------------------------
  // Create custom header when the pane is selected.
  protected override Widget create_header1() {

    var default_text = _( "Description (Optional)" );

    var entry = new EditableLabel( (table_item.description == "") ? default_text : table_item.description ) {
      halign = Align.FILL,
      hexpand = true
    };

    var editing_id = entry.notify["editing"].connect(() => {
      if( !entry.editing ) {
        var text = (entry.text == default_text) ? "" : entry.text;
        if( table_item.description != text ) {
          win.undo.add_item( new UndoItemDescChange( item, table_item.description ) );
          table_item.description = text;
          _h2_label.label = Utils.make_title( text );
        }
      }
    });
    add_signal( entry, editing_id );

    var save_id = save.connect(() => {
      var text = (entry.text == default_text) ? "" : entry.text;
      if( table_item.description != text ) {
        win.undo.add_item( new UndoItemDescChange( item, table_item.description ) );
        table_item.description = text;
        _h2_label.label = Utils.make_title( text );
      }
    });
    add_signal( this, save_id );

    var description_id = table_item.notify["description"].connect(() => {
      var text = (table_item.description == "") ? default_text : table_item.description;
      if( entry.text != text ) {
        entry.text = text;
        _h2_label.label = Utils.make_title( text );
      }
    });
    add_signal( table_item, description_id );

    var menu = new GLib.Menu();
    var popup_menu = new PopoverMenu.from_model( menu );

    // Add the settings
    add_auto_number_setting( menu, popup_menu );

    var settings = new MenuButton() {
      halign       = Align.END,
      has_frame    = false,
      icon_name    = "emblem-system-symbolic",
      tooltip_text = _( "Table Controls" ),
      popover      = popup_menu
    };

    var box = new Box( Orientation.HORIZONTAL, 5 ) {
      visible = (table_item.columns() > 0)
    };
    box.append( entry );
    box.append( settings );

    return( box );

  }

  //-------------------------------------------------------------
  // Returns true if the header2 widget is valid.
  protected override bool header2_exists() {
    return( table_item.description.chomp() != "" );
  }

  //-------------------------------------------------------------
  // Displays the secondary header when this note is not expanded.
  protected override Widget? create_header2() {
    _h2_label = new Label( table_item.description ) {
      use_markup = true,
      halign = Align.FILL,
      justify = Justification.CENTER
    };
    return( _h2_label );
  }

  //-------------------------------------------------------------
  // Returns the index of the column with the given ID.
  private int get_cv_column_index( string col_id ) {
    var store = (GLib.ListStore)_table.columns;
    for( int i=0; i<store.get_n_items(); i++ ) {
      var col = (ColumnViewColumn)store.get_item( i );
      if( col.id == col_id ) {
        return( i );
      }
    }
    return( -1 );
  }

  //-------------------------------------------------------------
  // Adds a new ColumnView column this will need to be called
  // when the user is adding a new column.
  public string add_cv_column( int index ) {

    var table_col  = table_item.get_column( index );
    var factory    = new SignalListItemFactory();
    var col_id_int = _col_id++;
    var col_id     = col_id_int.to_string();

    var setup_id = factory.setup.connect((obj) => {
      row_setup( col_id, obj );
    });
    add_signal( factory, setup_id );

    var teardown_id = factory.teardown.connect((obj) => {
      row_teardown( obj );
    });
    add_signal( factory, teardown_id );

    var bind_id = factory.bind.connect((obj) => {
      row_bind( col_id, obj );
    });
    add_signal( factory, bind_id );

    var unbind_id = factory.unbind.connect((obj) => {
      row_unbind( obj );
    });
    add_signal( factory, unbind_id );

    // Create menu
    var edit_menu = new GLib.Menu();
    edit_menu.append( _( "Format column" ), "table.action_format_column('%s')".printf( col_id ) );
    var ins_menu = new GLib.Menu();
    ins_menu.append( _( "Insert column before" ), "table.action_insert_column_before('%s')".printf( col_id ) );
    ins_menu.append( _( "Insert column after" ),  "table.action_insert_column_after('%s')".printf( col_id ) );
    var del_menu = new GLib.Menu();
    del_menu.append( _( "Remove column" ), "table.action_delete_column('%s')".printf( col_id ) );
    var head_menu = new GLib.Menu();
    head_menu.append_section( null, edit_menu );
    head_menu.append_section( null, ins_menu );
    head_menu.append_section( null, del_menu );

    var col = new ColumnViewColumn( table_col.header, factory ) {
      id          = col_id,
      expand      = table_item.get_column( index ).data_type.is_expandable(),
      resizable   = table_item.get_column( index ).data_type.is_resizable(),
      header_menu = head_menu
    };

    var title_id = column_title_changed.connect((id) => {
      if( id == col_id ) {
        col.title = table_col.header;
      }
    });
    add_signal( this, title_id );

    var type_id = column_type_changed.connect((id, old_type) => {
      if( id == col_id ) {
        var col_index = get_cv_column_index( col_id );
        col.expand    = table_item.get_column( col_index ).data_type.is_expandable();
        col.resizable = table_item.get_column( col_index ).data_type.is_resizable();
      }
    });
    add_signal( this, type_id );

    _table.insert_column( index, col );

    return( col_id );

  }

  //-------------------------------------------------------------
  // Removes the ColumnView column at the given index.
  public void remove_cv_column( int index ) {
    var columns = (GLib.ListStore)_table.columns;
    var column  = (ColumnViewColumn)columns.get_item( index );
    if( column != null ) {
      _table.remove_column( column );
    }
  }

  //-------------------------------------------------------------
  // Creates the table maker interface.
  private Widget create_table_maker( Stack stack ) {

    var title = new Label( Utils.make_title( _( "Configure Table" ) ) ) {
      margin_bottom = 10,
      use_markup = true
    };

    var col_lbl = new Label( _( "Columns:" ) ) {
      xalign = (float)0.0
    };
    var col_sb  = new SpinButton.with_range( 1.0, 10.0, 1.0 );

    var row_lbl = new Label( _( "Rows:" ) ) {
      xalign = (float)0.0
    };
    var row_sb  = new SpinButton.with_range( 1.0, 100.0, 1.0 );

    var rnum = new CheckButton.with_label( _( "Show row numbers" ) );

    var create = new Button.with_label( _( "Create Table" ) ) {
      halign = Align.END,
      hexpand = true
    };

    var clicked_id = create.clicked.connect(() => {
      for( int i=0; i<(int)col_sb.value; i++ ) {
        table_item.insert_column( i, _( "Column %d" ).printf( i ), Gtk.Justification.LEFT, TableColumnType.TEXT );
      }
      for( int i=0; i<(int)row_sb.value; i++ ) {
        table_item.insert_row( i );
      }
      table_item.auto_number = rnum.active;
      for( int i=0; i<table_item.columns(); i++ ) {
        add_cv_column( i );
      }
      header1.visible = true;
      stack.visible_child_name = "table";
    });
    add_signal( create, clicked_id );

    var bbox = new Box( Orientation.HORIZONTAL, 5 );
    bbox.append( create );

    var grid = new Grid() {
      halign = Align.CENTER,
      valign = Align.CENTER,
      row_spacing = 10,
      column_spacing = 10
    };
    grid.attach( title,   0, 0, 2 );
    grid.attach( col_lbl, 0, 1 );
    grid.attach( col_sb,  1, 1 );
    grid.attach( row_lbl, 0, 2 );
    grid.attach( row_sb,  1, 2 );
    grid.attach( rnum,    0, 3, 2 );
    grid.attach( bbox,    0, 4, 2 );

    var box = new Box( Orientation.VERTICAL, 0 );
    box.append( grid );

    return( box );

  }

  //-------------------------------------------------------------
  // Adds the UI for the table panel.
  protected override Widget create_pane() {

    var selector = new SingleSelection( table_item.model );

    _table = new ColumnView( selector ) {
      // tab_behavior = ListTabBehavior.ALL,
      halign = Align.FILL,
      show_row_separators = true,
      show_column_separators = true
    };
    _table.add_css_class( "table-border" );

    var stack = new Stack();

    var maker = create_table_maker( stack );

    stack.add_named( _table, "table" );
    stack.add_named( maker,  "maker" );

    if( table_item.columns() == 0 ) {
      stack.visible_child_name = "maker";
    } else {
      stack.visible_child_name = "table";
      for( int i=0; i<table_item.columns(); i++ ) {
        add_cv_column( i );
      }
    }

    return( stack );

  }

  //-------------------------------------------------------------
  // Performs note search over this table contents.
  public override void do_search( NoteSearchFunc command ) {
    command( this, "desc", table_item.description, _h2_label );
    bool[] check_cols = {};
    var columns = table_item.columns();
    for( int i=0; i<columns; i++ ) {
      check_cols += (table_item.get_column( i ).data_type == TableColumnType.TEXT);
    }
    for( int i=0; i<table_item.rows(); i++ ) {
      var row = table_item.get_row( i );
      for( int j=0; j<columns; j++ ) {
        if( check_cols[j] ) {
          command( this, "cell:%d:%d".printf( i, j ), row.get_value( j ), _table );  // TODO
        }
      }
    }
  }

  //-------------------------------------------------------------
  // Saves the given text value to the cell associated with the given
  // list item and column index.
  private void save_to_cell( ListItem li, int column, string val ) {
    var row = (int)li.position;
    table_item.set_cell( column, row, val );
  }

  //-------------------------------------------------------------
  // Creates an auto-numbered cell whose value is the position of the
  // list item in the list plus one.
  private Box setup_auto_number( string? num = null ) {

    var label = new Label( num ?? "" ) {
      valign = Align.START,
      wrap = false
    };

    var box = new Box( Orientation.VERTICAL, 0 ) {
      halign = Align.START
    };
    box.append( label );

    return( box );

  }

  //-------------------------------------------------------------
  // Setups up a text widget for the given cell.
  private TextView setup_text( int column, ListItem li ) {

    var text = new TextView() {
      halign        = Align.FILL,
      hexpand       = true,
      justification = ((NoteItemTable)item).get_column( column ).justify,
      wrap_mode     = WrapMode.WORD,
      right_margin  = 5,
      left_margin   = 5,
      top_margin    = 5,
      bottom_margin = 5
    };

    text.extra_menu = create_row_contextual_menu( li );

    var focus_controller = new EventControllerFocus();
    li.set_data<EventControllerFocus>( "text-focus-controller", focus_controller );

    var key_controller = new EventControllerKey();
    li.set_data<EventControllerKey>( "text-key-controller", key_controller );

    text.add_controller( focus_controller );
    text.add_controller( key_controller );

    return( text );

  }

  //-------------------------------------------------------------
  // Returns the align value for the given Justification enumerated
  // value.
  private Align align_from_justify( Justification justify ) {
    switch( justify ) {
      case Justification.LEFT   :  return( Align.START );
      case Justification.CENTER :  return( Align.CENTER );
      case Justification.RIGHT  :  return( Align.END );
      default                   :  return( Align.START );
    }
  }

  //-------------------------------------------------------------
  // Sets up a checkbox for a given row.
  private CheckButton setup_checkbox( int column, ListItem li ) {

    var cb = new CheckButton() {
      halign = align_from_justify( ((NoteItemTable)item).get_column( column ).justify ),
      hexpand = true
    };
    li.set_data<CheckButton>( "check-cb", cb );

    return( cb );

  }

  //-------------------------------------------------------------
  // Sets up a date picker for a given column/row.
  private Box setup_date( int column, ListItem li ) {

    var cal = new Calendar() {
      halign = Align.END
    };
    li.set_data<Calendar>( "date-cal", cal );

    var clear = new Button.with_label( _( "Clear date" ) ) {
      has_frame = false
    };
    li.set_data<Button>( "date-clear", clear );

    var cbox = new Box( Orientation.VERTICAL, 5 );
    cbox.append( cal );
    cbox.append( clear );

    var popup = new Popover() {
      child = cbox
    };

    var mb = new MenuButton() {
      halign            = align_from_justify( table_item.get_column( column ).justify ),
      label             = "",
      icon_name         = "x-office-calendar-symbolic",
      popover           = popup,
      always_show_arrow = false,
      has_frame         = false,
      direction         = ArrowType.NONE
    };
    li.set_data<MenuButton>( "date-mb", mb );

    var box = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.FILL,
      hexpand = true
    };
    box.append( mb );

    return( box );

  }

  //-------------------------------------------------------------
  // Row factory setup function
  private void row_setup( string col_id, Object obj ) {

    var li         = (ListItem)obj;
    var column     = get_cv_column_index( col_id );
    var row_id_int = _row_id++;
    var row_id     = row_id_int.to_string();

    _row_map.set( row_id, li );

    li.set_data<string>( "row-id", row_id );
    li.set_data<bool>( "init-resize", true );

    var box = new Box( Orientation.HORIZONTAL, 5 ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };
    li.set_data<Box>( "row-box", box );

    if( (column == 0) && table_item.auto_number ) {
      box.append( setup_auto_number() );
    }

    switch( table_item.get_column( column ).data_type ) {
      case TableColumnType.TEXT     :  box.append( setup_text( column, li ) );      break;
      case TableColumnType.CHECKBOX :  box.append( setup_checkbox( column, li ) );  break;
      case TableColumnType.DATE     :  box.append( setup_date( column, li ) );      break;
      default                       :  assert_not_reached();
    }

    li.child = box;

    var left_click = new GestureClick() {
      button = Gdk.BUTTON_PRIMARY
    };
    li.set_data<Object>( "left-click", left_click );

    var right_click = new GestureClick() {
      button = Gdk.BUTTON_SECONDARY
    };
    li.set_data<Object>( "right-click", right_click );

    box.add_controller( left_click );
    box.add_controller( right_click );

  }

  //-------------------------------------------------------------
  // Called whenever a row is removed from the table.
  private void row_teardown( Object obj ) {

    var li = (ListItem)obj;

    var row_id = li.get_data<string>( "row-id" );
    if( row_id != null ) {
      _row_map.unset( row_id );
    }

  }

  //-------------------------------------------------------------
  // Creates the contextual menu for manipulating rows.
  private GLib.Menu create_row_contextual_menu( ListItem li ) {

    var row_id = li.get_data<string>( "row-id" );

    var add_menu = new GLib.Menu();
    add_menu.append( _( "Insert row above" ), "table.action_insert_row_above('%s')".printf( row_id ) );
    add_menu.append( _( "Insert row below" ), "table.action_insert_row_below('%s')".printf( row_id ) );
    var del_menu = new GLib.Menu();
    del_menu.append( _( "Remove row" ), "table.action_delete_row('%s')".printf( row_id ) );
    var menu = new GLib.Menu();
    menu.append_section( null, add_menu );
    menu.append_section( null, del_menu );

    return( menu );

  }

  //-------------------------------------------------------------
  // Creates and displays the contextual menu for manipulating rows.
  private void show_row_contextual_menu( Box box, ListItem li ) {

    var menu = create_row_contextual_menu( li );
    var popover = new PopoverMenu.from_model( menu ) {
      has_arrow = false
    };
    popover.set_parent( box );
    popover.popup();

  }

  //-------------------------------------------------------------
  // Binds the associated text to the listitem value.
  private void bind_text( int column, ListItem li ) {

    var row  = (NoteItemTableRow)li.item;
    var text = (TextView)li.child.get_last_child();
    var val  = row.get_value( column );

    text.buffer.text = val;

    var focus_controller = li.get_data<EventControllerFocus>( "text-focus-controller" );
    var enter_id = focus_controller.enter.connect(() => {
      _table.model.select_item( li.get_position(), true );
    });
    li.set_data<ulong>( "text-focus-enter-id", enter_id );

    var leave_id = focus_controller.leave.connect(() => {
      save_to_cell( li, column, text.buffer.text );
    });
    li.set_data<ulong>( "text-focus-leave-id", leave_id );

    // If we need to save, check to see if a table cell has focus and
    // save its contents to the note item
    var save_id = save.connect(() => {
      if( focus_controller.contains_focus ) {
        save_to_cell( li, column, text.buffer.text );
      }
    });
    li.set_data<ulong>( "save-id", save_id );

    var key_controller = li.get_data<EventControllerKey>( "text-key-controller" );
    var key_press_id = key_controller.key_pressed.connect((keyval, keycode, state) => {
      switch( keyval ) {
        case Gdk.Key.Tab          :  _table.child_focus( DirectionType.TAB_FORWARD );   return( true );
        case Gdk.Key.ISO_Left_Tab :  _table.child_focus( DirectionType.TAB_BACKWARD );  return( true );
        default                   :  return( false );
      }
    });
    li.set_data<ulong>( "text-key-press-id", key_press_id );

    // Force a re-measure once GtkTextView's own lazy layout validation
    // has had a chance to run, in case its natural size changes after
    // validation without automatically triggering a resize.
    if( li.get_data<bool>( "init-resize" ) ) {
      Idle.add(() => {
        text.queue_resize();
        li.child.queue_resize();
        return( false );
      }, GLib.Priority.LOW );
      li.set_data<bool>( "init-resize", false );
    }

  }

  //-------------------------------------------------------------
  // Undoes the binding in bind_text.
  private void unbind_text( ListItem li ) {

    var focus_controller = li.get_data<EventControllerFocus>( "text-focus-controller" );
    var focus_enter_id   = li.get_data<ulong>( "text-focus-enter-id" );
    if( focus_enter_id != 0 ) {
      SignalHandler.disconnect( focus_controller, focus_enter_id );
      li.set_data<ulong>( "text-focus-enter-id", 0 );
    }

    var focus_leave_id   = li.get_data<ulong>( "text-focus-leave-id" );
    if( focus_leave_id != 0 ) {
      SignalHandler.disconnect( focus_controller, focus_leave_id );
      li.set_data<ulong>( "text-focus-leave-id", 0 );
    }

    var key_controller = li.get_data<EventControllerKey>( "text-key-controller" );
    var key_press_id   = li.get_data<ulong>( "text-key-press-id" );
    if( key_press_id != 0 ) {
      SignalHandler.disconnect( key_controller, key_press_id );
      li.set_data<ulong>( "text-key-press-id", 0 );
    }

  }

  //-------------------------------------------------------------
  // Binds the associated checkbutton to the listitem value.
  private void bind_checkbox( int column, ListItem li ) {

    var row      = (NoteItemTableRow)li.item;
    var checkbox = li.get_data<CheckButton>( "check-cb" );

    checkbox.active = bool.parse( row.get_value( column ) );

    var notify_id = checkbox.notify["active"].connect(() => {
      save_to_cell( li, column, checkbox.active.to_string() );
    });
    li.set_data<ulong>( "check-cb-notify-id", notify_id );

  }

  //-------------------------------------------------------------
  // Undoes any binding done in the bind_checkbox method.
  private void unbind_checkbox( ListItem li ) {

    var cb = li.get_data<CheckButton>( "check-cb" );
    var notify_id = li.get_data<ulong>( "check-cb-notify-id" );
    if( notify_id != 0 ) {
      SignalHandler.disconnect( cb, notify_id );
      li.set_data<ulong>( "check-cb-notify-id", 0 );
    }

  }

  //-------------------------------------------------------------
  // Updates the date widget to the current value.
  private void bind_date( int column, ListItem li ) {

    var row   = (NoteItemTableRow)li.item;
    var mb    = li.get_data<MenuButton>( "date-mb" );
    var cal   = li.get_data<Calendar>( "date-cal" );
    var clear = li.get_data<Button>( "date-clear" );
    var pop   = mb.popover;
    var dt    = new DateTime.from_iso8601( row.get_value( column ), null );

    if( dt == null ) {
      dt = new DateTime.now_local();
      mb.label = null;
      mb.icon_name = "x-office-calendar-symbolic";
    } else {
      mb.icon_name = null;
      mb.label = dt.format( "%b %e, %Y" );
    }

    cal.day   = dt.get_day_of_month();
    cal.month = dt.get_month();
    cal.year  = dt.get_year();

    var clear_id = clear.clicked.connect(() => {
      mb.label     = null;
      mb.icon_name = "x-office-calendar-symbolic";
      save_to_cell( li, column, "" );
      mb.popover.popdown();
    });
    li.set_data<ulong>( "date-clear-click-id", clear_id );

    var select_id = cal.day_selected.connect(() => {
      var date = cal.get_date();
      mb.label = date.format( "%b %e, %Y" );
      save_to_cell( li, column, date.format_iso8601() );
      mb.popover.popdown();
    });
    li.set_data<ulong>( "date-cal-select-id", select_id );

  }

  //-------------------------------------------------------------
  // Unbinds the date.
  private void unbind_date( ListItem li ) {

    var clear     = li.get_data<Button>( "date-clear" );
    var clear_id  = li.get_data<ulong>( "date-clear-click-id" );
    if( clear_id != 0 ) {
      SignalHandler.disconnect( clear, clear_id );
      li.set_data<ulong>( "date-clear-click-id", 0 );
    }

    var cal       = li.get_data<Calendar>( "date-cal" );
    var select_id = li.get_data<ulong>( "date-cal-select-id" );
    if( select_id != 0 ) {
      SignalHandler.disconnect( cal, select_id );
      li.set_data<ulong>( "date-cal-select-id", 0 );
    }

  }

  //-------------------------------------------------------------
  // Row factory bind function
  private void row_bind( string col_id, Object obj ) {

    var li     = (ListItem)obj;
    var column = get_cv_column_index( col_id );

    if( (column == 0) && table_item.auto_number ) {
      var lbl = (Label)li.child.get_first_child().get_first_child();
      lbl.label = "%u.".printf( li.get_position() + 1 );
    }

    var auto_number_id = auto_number_changed.connect(() => {
      var col_index = get_cv_column_index( col_id );
      if( col_index == 0 ) {
        var b = (Box)li.child;
        if( table_item.auto_number ) {
          b.prepend( setup_auto_number( "%u.".printf( li.get_position() + 1 ) ) );
        } else {
          b.remove( b.get_first_child() );
        }
      }
    });
    li.set_data<ulong>( "auto-number-id", auto_number_id );

    var justify_id = column_justify_changed.connect((id) => {
      if( id == col_id ) {
        var justify = table_item.get_column( column ).justify;
        var child   = li.child.get_last_child();
        switch( table_item.get_column( column ).data_type ) {
          case TableColumnType.TEXT     :  ((TextView)child).justification = justify;  break;
          case TableColumnType.CHECKBOX :  ((CheckButton)child).halign = align_from_justify( justify );  break;
          case TableColumnType.DATE     :  ((MenuButton)child.get_first_child().get_first_child()).halign = align_from_justify( justify );  break;
          default                       :  assert_not_reached();
        }
      }
    });
    li.set_data<ulong>( "justify-id", justify_id );

    var type_id = column_type_changed.connect((id, old_type) => {
      if( id == col_id ) {
        var b = (Box)li.child;
        b.remove( b.get_last_child() );
        switch( old_type ) {
          case TableColumnType.TEXT     :  unbind_text( li );      break;
          case TableColumnType.CHECKBOX :  unbind_checkbox( li );  break;
          case TableColumnType.DATE     :  unbind_date( li );      break;
          default                       :  break;
        }
        switch( table_item.get_column( column ).data_type ) {
          case TableColumnType.TEXT :
            b.append( setup_text( column, li ) );
            bind_text( column, li );
            break;
          case TableColumnType.CHECKBOX :
            b.append( setup_checkbox( column, li ) );
            bind_checkbox( column, li );
            break;
          case TableColumnType.DATE :
            b.append( setup_date( column, li ) );
            bind_date( column, li );
            break;
          default :  assert_not_reached();
        }
      }
    });
    li.set_data<ulong>( "type-id", type_id );

    var left_click = (GestureClick)li.get_data<Object>( "left-click" );
    var left_id    = left_click.pressed.connect((n, x, y) => {
      var child = li.child.get_last_child();
      switch( table_item.get_column( column ).data_type ) {
        case TableColumnType.TEXT     :  Idle.add(() => { child.grab_focus(); return( false ); });  break;
        case TableColumnType.CHECKBOX :  child.grab_focus();  break;
        case TableColumnType.DATE     :  child.get_first_child().get_first_child().grab_focus();  break;
        default                       :  assert_not_reached();
      }
    });
    li.set_data<ulong>( "left-id", left_id );

    var right_click = (GestureClick)li.get_data<Object>( "right-click" );
    var box         = li.get_data<Box>( "row-box" );
    var right_id    = right_click.pressed.connect((n, x, y) => {
      _table.model.select_item( li.get_position(), true );
      show_row_contextual_menu( box, li );
    });
    li.set_data<ulong>( "right-id", right_id );

    switch( table_item.get_column( column ).data_type ) {
      case TableColumnType.TEXT     :  bind_text( column, li );      break;
      case TableColumnType.CHECKBOX :  bind_checkbox( column, li );  break;
      case TableColumnType.DATE     :  bind_date( column, li );      break;
      default                       :  assert_not_reached();
    }

  }

  //-------------------------------------------------------------
  // Undoes the lasting effects of row_bind.
  private void row_unbind( Object obj ) {

    var li = (ListItem)obj;

    var auto_number_id = li.get_data<ulong>( "auto-number-id" );
    if( auto_number_id != 0 ) {
      SignalHandler.disconnect( this, auto_number_id );
    }

    var justify_id = li.get_data<ulong>( "justify-id" );
    if( justify_id != 0 ) {
      SignalHandler.disconnect( this, justify_id );
    }

    var type_id = li.get_data<ulong>( "type-id" );
    if( type_id != 0 ) {
      SignalHandler.disconnect( this, type_id );
    }

    var save_id = li.get_data<ulong>( "save-id" );
    if( save_id != 0 ) {
      SignalHandler.disconnect( this, save_id );
    }

    var left_id = li.get_data<ulong>( "left-id" );
    var left_click = li.get_data<Object>( "left-click" );
    if( left_id != 0 ) {
      SignalHandler.disconnect( left_click, left_id );
    }

    var right_id = li.get_data<ulong>( "right-id" );
    var right_click = li.get_data<Object>( "right-click" );
    if( right_id != 0 ) {
      SignalHandler.disconnect( right_click, right_id );
    }

    unbind_text( li );
    unbind_checkbox( li );
    unbind_date( li );

  }

  //-------------------------------------------------------------
  // Displays the column formatting dialog window.
  private void show_column_format_dialog( string col_id, bool after_add ) {

    var index  = get_cv_column_index( col_id );
    var column = table_item.get_column( index );
    var undo   = new UndoItemTableColFormat( this, table_item, col_id, index );

    var grid = new Grid() {
      margin_start    = 10,
      margin_end      = 10,
      margin_top      = 10,
      margin_bottom   = 10,
      row_homogeneous = true,
      column_spacing  = 10,
      row_spacing     = 10
    };

    var title_label = new Label( _( "Title:" ) ) {
      halign = Align.START,
      hexpand = true
    };
    grid.attach( title_label, 0, 0 );

    var title_entry = new Entry() {
      halign = Align.START,
      hexpand = true,
      text = column.header
    };
    grid.attach( title_entry, 1, 0 );

    var title_focus = new EventControllerFocus();
    title_entry.add_controller( title_focus );

    var leave_id = title_focus.leave.connect(() => {
      column.header = title_entry.text;
      column_title_changed( col_id );
    });
    add_signal( title_focus, leave_id );

    var type_label = new Label( _( "Content Type:" ) ) {
      halign = Align.START,
      hexpand = true
    };
    grid.attach( type_label, 0, 1 );

    string[] types = {};
    for( int i=0; i<TableColumnType.NUM; i++ ) {
      var col_type = (TableColumnType)i;
      types += col_type.label();
    }

    var type_menu = new DropDown.from_strings( types ) {
      halign = Align.START,
      hexpand = true,
      selected = column.data_type
    };
    grid.attach( type_menu, 1, 1 );

    var selected_id = type_menu.notify["selected"].connect(() => {
      var old_type = column.data_type;
      column.data_type = (TableColumnType)type_menu.selected;
      column_type_changed( col_id, old_type );
    });
    add_signal( type_menu, selected_id );

    var justify_label = new Label( _( "Justify:" ) ) {
      halign = Align.START,
      hexpand = true
    };
    grid.attach( justify_label, 0, 2 );

    var justify_menu = new DropDown.from_strings( { _( "Left" ), _( "Center" ), _( "Right" ) } ) {
      halign = Align.START,
      hexpand = true,
      selected = column.justify
    };
    grid.attach( justify_menu, 1, 2 );

    switch( column.justify ) {
      case Justification.LEFT   :  justify_menu.selected = 0;  break;
      case Justification.CENTER :  justify_menu.selected = 1;  break;
      case Justification.RIGHT  :  justify_menu.selected = 2;  break;
      default                   :  assert_not_reached();
    }

    var justify_id = justify_menu.notify["selected"].connect(() => {
      switch( justify_menu.selected ) {
        case 0 :  column.justify = Justification.LEFT;    break;
        case 1 :  column.justify = Justification.CENTER;  break;
        case 2 :  column.justify = Justification.RIGHT;   break;
      }
      column_justify_changed( col_id );
    });
    add_signal( justify_menu, justify_id );

    var dialog = new Window() {
      decorated = true,
      modal = true,
      destroy_with_parent = true,
      resizable = false,
      title = _( "Format Column" ),
      transient_for = win,
      child = grid
    };

    dialog.close_request.connect(() => {
      if( after_add ) {
        Idle.add(() => {
          win.undo.add_item( new UndoItemTableInsCol( this, table_item, index ) );
          return( false );
        });
      } else if( undo.changed( column ) ) {
        win.undo.add_item( undo );
      }
      return( false );
    });

    dialog.present();

  }

  //-------------------------------------------------------------
  // Edits the column title for the specified column.
  private void action_format_column( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var col_id = variant.get_string();
      show_column_format_dialog( col_id, false );
    }
  }

  //-------------------------------------------------------------
  // Inserts a new column at the specified index.
  private void action_insert_column_before( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var col_id = variant.get_string();
      var index  = get_cv_column_index( col_id );
      table_item.insert_column( index, "", Gtk.Justification.LEFT, TableColumnType.TEXT );
      col_id = add_cv_column( index );
      show_column_format_dialog( col_id, true );
      win.undo.add_item( new UndoItemTableInsCol( this, table_item, index ) );
    }
  }

  //-------------------------------------------------------------
  // Inserts a new column at the specified index.
  private void action_insert_column_after( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var col_id = variant.get_string();
      var index  = get_cv_column_index( col_id );
      table_item.insert_column( (index + 1), "", Gtk.Justification.LEFT, TableColumnType.TEXT );
      col_id = add_cv_column( index + 1 );
      show_column_format_dialog( col_id, true );
    }
  }

  //-------------------------------------------------------------
  // Removes the column at the specified index.
  private void action_delete_column( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var col_id = variant.get_string();
      var index  = get_cv_column_index( col_id );
      win.undo.add_item( new UndoItemTableDelCol( this, table_item, index ) );
      table_item.delete_column( index );
      remove_cv_column( index );
    }
  }

  //-------------------------------------------------------------
  // Inserts a new row before the passed row position.
  private void action_insert_row_above( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var row_id = variant.get_string();
      var row_li = _row_map.get( row_id );
      var index  = (int)row_li.get_position();
      table_item.insert_row( index );
      win.undo.add_item( new UndoItemTableInsRow( table_item, index ) );
    }
  }

  //-------------------------------------------------------------
  // Inserts a new row before the passed row position.
  private void action_insert_row_below( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var row_id = variant.get_string();
      var row_li = _row_map.get( row_id );
      var index  = (int)row_li.get_position() + 1;
      table_item.insert_row( (int)index );
      win.undo.add_item( new UndoItemTableInsRow( table_item, index ) );
    }
  }

  //-------------------------------------------------------------
  // Deletes the row at the passed row position.
  private void action_delete_row( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var row_id = variant.get_string();
      var row_li = _row_map.get( row_id );
      var index  = (int)row_li.get_position();
      win.undo.add_item( new UndoItemTableDelRow( table_item, index ) );
      table_item.delete_row( index );
    }
  }

  //-------------------------------------------------------------
  // Copies the table in Markdown format to the clipboard.
  protected override void copy_to_clipboard( Gdk.Clipboard clipboard ) {
    clipboard.set_text( item.to_markdown( win.notebooks, true, false ) );
  }

}
