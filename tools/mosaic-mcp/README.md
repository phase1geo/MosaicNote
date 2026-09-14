# mosaic-mcp

A read-only [MCP](https://modelcontextprotocol.io) server that exposes
MosaicNote's on-disk XML notebook database to AI tools like Claude Desktop
or Claude Code.

It runs as a standalone companion process — it does not talk to MosaicNote
itself, it just reads the same XML files MosaicNote writes to
`~/.local/share/mosaic-note`.

## What it assumes about MosaicNote's data layout

```
~/.local/share/mosaic-note/
    notebooks.xml               top-level index of notebooks
    notebooks/
        notebook-<id>/
            notebook.xml         all notes for that notebook
            resources/           files referenced by <asset> blocks
```

- `notebooks.xml` has an `inbox-id`, `trash-id`, and `templates-id` attribute
  identifying three built-in notebooks that always exist but aren't listed
  as `<node>` children, plus a `<node id="..." name="..."/>` per
  user-created notebook.
- A notebook's directory name under `notebooks/` is `notebook-` followed
  by its numeric `id` (e.g. the Inbox notebook, `id="0"`, lives at
  `notebooks/notebook-0/notebook.xml`). If this naming scheme ever
  changes, only `MosaicNoteStore._notebook_xml_path()` in `xml_parser.py`
  needs to change.
- A note is a `<note>` element containing `<tags>` and `<rows>`. Each
  `<row>` holds one or more content blocks side by side. Recognized block
  types: `markdown`, `table` (with `<columns>`/`<rows>`/`<cell>`), `math`,
  `uml`, `image`, `assets` (with `<asset>` children), and `flash`
  (flashcards with `<card><side1>/<side2>`). Any other block type is still
  read (as raw text) so nothing is silently dropped if MosaicNote adds new
  block types later — but it won't be parsed into a richer structure until
  `_parse_block()` in `xml_parser.py` is extended for it.

## Install

Requires Python 3.10+.

On Debian/Ubuntu (and most current Linux distros), the system Python is
"externally managed" (PEP 668) and refuses a bare `pip install`. Use a
virtual environment — this is the standard approach, not a workaround:

```bash
cd mosaic-mcp
python3 -m venv venv
venv/bin/pip install -e .
```

This installs the `mcp` SDK (v2.x) and the `mosaic-mcp` command into
`venv/`, isolated from your system Python.

## Configure your MCP client

The server reads `MOSAIC_NOTE_DATA_DIR` for the data directory, defaulting
to `~/.local/share/mosaic-note` if unset.

For Claude Desktop, add to `claude_desktop_config.json`, using the **full
path** to the venv's `mosaic-mcp` command (it isn't on your system `PATH`):

```json
{
  "mcpServers": {
    "mosaic-note": {
      "command": "/path/to/mosaic-mcp/venv/bin/mosaic-mcp"
    }
  }
}
```

Or point at the venv's interpreter and the module directly (equivalent,
useful if you'd rather not rely on the installed script entry point):

```json
{
  "mcpServers": {
    "mosaic-note": {
      "command": "/path/to/mosaic-mcp/venv/bin/python3",
      "args": ["-m", "mosaic_mcp.server"],
      "cwd": "/path/to/mosaic-mcp",
      "env": {
        "MOSAIC_NOTE_DATA_DIR": "/home/youruser/.local/share/mosaic-note"
      }
    }
  }
}
```

`MOSAIC_NOTE_DATA_DIR` is optional in both forms above — only set it if
your data directory isn't the default `~/.local/share/mosaic-note`.

## Tools exposed

| Tool | Purpose |
|---|---|
| `list_notebooks()` | List every notebook (id, name, and whether it's the built-in Inbox/Trash/Templates). |
| `list_notes(notebook_id)` | List notes in a notebook: id, title, timestamps, favorite/locked flags, tags, and a short text preview. |
| `get_note(notebook_id, note_id)` | Full content of one note: every row and block in order, with type-specific fields (markdown text, table columns/rows, math/UML source, image URI, flashcard sides, asset paths). |
| `search_notes(query, notebook_id=None)` | Case-insensitive substring search over title, tags, and all block content/text fields, optionally scoped to one notebook. |

All four are read-only — nothing in this server writes to the XML files.

## Project layout

```
mosaic_mcp/
    xml_parser.py   XML parsing — no MCP dependency, usable/testable standalone
    server.py       MCP tool definitions built on top of xml_parser
pyproject.toml
```

## Known limitations / next steps

- Note content and titles found empty in the sample data (`title=""`) are
  common — MosaicNote appears to let notes go untitled, so `list_notes`
  previews fall back to the first ~200 characters of body text.
- `search_notes` loads and parses every `notebook.xml` on each call. Fine
  for typical personal notebook sizes; if a user's database gets very
  large this could be swapped for an on-disk index later.
- Asset file *contents* (files under a notebook's `resources/` directory,
  or arbitrary paths referenced by `<asset path="file://...">`) are not
  read — only their paths are returned. Add a `read_asset` tool if the
  model should be able to open attachments directly.
- No write/edit tools yet, matching the current read-only scope.
