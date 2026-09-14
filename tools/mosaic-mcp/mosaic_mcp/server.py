"""
MCP server exposing read-only access to a MosaicNote data directory.

Run directly (stdio transport, the standard way MCP clients launch servers):

    MOSAIC_NOTE_DATA_DIR=~/.local/share/mosaic-note python -m mosaic_mcp.server

If MOSAIC_NOTE_DATA_DIR is not set, it defaults to
~/.local/share/mosaic-note.
"""

from __future__ import annotations

import os
from typing import Any, Optional

from mcp.server.mcpserver import MCPServer
from mcp.server.mcpserver.exceptions import ToolError

from .xml_parser import Block, MosaicNoteError, MosaicNoteStore, Note, Notebook, Row

DEFAULT_DATA_DIR = "~/.local/share/mosaic-note"

mcp = MCPServer(
    name="mosaic-note",
    version="0.1.0",
    instructions=(
        "Read-only access to a MosaicNote notebook database. "
        "Use list_notebooks to see what notebooks exist, list_notes to browse "
        "a notebook, get_note to fetch a note's full content, and search_notes "
        "to find notes by keyword."
    ),
)

_store: Optional[MosaicNoteStore] = None


def get_store() -> MosaicNoteStore:
    global _store
    if _store is None:
        data_dir = os.environ.get("MOSAIC_NOTE_DATA_DIR", DEFAULT_DATA_DIR)
        _store = MosaicNoteStore(data_dir)
    return _store


# -- serialization helpers --------------------------------------------------


def _notebook_dict(nb: Notebook) -> dict[str, Any]:
    return {"id": nb.id, "name": nb.name, "special": nb.special}


def _block_dict(block: Block) -> dict[str, Any]:
    d: dict[str, Any] = {"type": block.type, "id": block.id, "presentable": block.presentable}
    if block.description:
        d["description"] = block.description
    if block.text is not None:
        d["text"] = block.text
    if block.extra:
        d.update(block.extra)
    return d


def _row_dict(row: Row) -> dict[str, Any]:
    return {"expanded": row.expanded, "blocks": [_block_dict(b) for b in row.blocks]}


def _note_summary_dict(note: Note) -> dict[str, Any]:
    """Lightweight representation for list views: metadata + a short preview, no full content."""
    preview_parts: list[str] = []
    for row in note.rows:
        for block in row.blocks:
            if block.text:
                preview_parts.append(block.text)
        if sum(len(p) for p in preview_parts) > 200:
            break
    preview = " ".join(preview_parts).replace("\n", " ").strip()
    if len(preview) > 200:
        preview = preview[:200].rstrip() + "…"

    return {
        "id": note.id,
        "title": note.title,
        "created": note.created,
        "updated": note.updated,
        "favorite": note.favorite,
        "locked": note.locked,
        "tags": note.tags,
        "preview": preview,
    }


def _note_full_dict(note: Note) -> dict[str, Any]:
    return {
        "id": note.id,
        "title": note.title,
        "created": note.created,
        "updated": note.updated,
        "viewed": note.viewed,
        "locked": note.locked,
        "favorite": note.favorite,
        "tags": note.tags,
        "rows": [_row_dict(r) for r in note.rows],
    }


# -- tools --------------------------------------------------------------


@mcp.tool()
def list_notebooks() -> list[dict[str, Any]]:
    """List all notebooks in the MosaicNote database, including the built-in
    Inbox, Trash, and Templates notebooks. Returns each notebook's id, name,
    and special role (if any)."""
    try:
        return [_notebook_dict(nb) for nb in get_store().list_notebooks()]
    except MosaicNoteError as e:
        raise ToolError(str(e)) from e


@mcp.tool()
def list_notes(notebook_id: str) -> list[dict[str, Any]]:
    """List the notes in a given notebook (by notebook id, as returned by
    list_notebooks). Returns metadata and a short text preview for each note,
    not full content — use get_note for that."""
    try:
        return [_note_summary_dict(n) for n in get_store().list_notes(notebook_id)]
    except MosaicNoteError as e:
        raise ToolError(str(e)) from e


@mcp.tool()
def get_note(notebook_id: str, note_id: str) -> dict[str, Any]:
    """Fetch the full content of a single note, including every row and block
    (markdown text, tables, math, UML, images, flashcards, and asset
    references) in their original order."""
    try:
        return _note_full_dict(get_store().get_note(notebook_id, note_id))
    except MosaicNoteError as e:
        raise ToolError(str(e)) from e


@mcp.tool()
def search_notes(query: str, notebook_id: Optional[str] = None) -> list[dict[str, Any]]:
    """Case-insensitive search for notes containing the given text in their
    title, tags, or block content (markdown, table cells, flashcard sides,
    asset paths, etc). Optionally restrict the search to one notebook id."""
    try:
        results = get_store().search_notes(query, notebook_id=notebook_id)
    except MosaicNoteError as e:
        raise ToolError(str(e)) from e

    return [
        {
            "notebook_id": nb.id,
            "notebook_name": nb.name,
            **_note_summary_dict(note),
        }
        for nb, note in results
    ]


def main() -> None:
    mcp.run()


if __name__ == "__main__":
    main()
