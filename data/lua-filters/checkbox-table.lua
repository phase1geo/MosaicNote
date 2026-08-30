-- checkbox-table.lua
-- Converts a leading "[ ]" / "[x]" / "[X]" in a table cell into
-- an actual checkbox input, mirroring what task_lists already
-- does for bullet list items.

local function cell_to_checkbox(cell)
  if #cell.contents == 0 then return cell end
  local first_block = cell.contents[1]
  if not (first_block.t == "Plain" or first_block.t == "Para") then
    return cell
  end

  local inlines = first_block.content
  local acc, consumed, marker, rest = "", 0, nil, nil

  -- The "[ ]"/"[x]" marker can span up to 3 separate inlines once
  -- Pandoc's reader splits on the internal space (Str"[", Space,
  -- Str"]"), so accumulate text across the first few rather than
  -- assuming it's all one Str token.
  for i = 1, math.min(4, #inlines) do
    local inline = inlines[i]
    local text
    if inline.t == "Str" then text = inline.text
    elseif inline.t == "Space" or inline.t == "SoftBreak" then text = " "
    else break end

    acc = acc .. text
    consumed = i
    marker, rest = acc:match("^%[([xX ])%](.*)$")
    if marker then break end
  end

  if not marker then return cell end

  local checkbox = pandoc.RawInline("html",
    string.format('<input type="checkbox"%s disabled="">',
      marker ~= " " and ' checked=""' or ''))

  local new_inlines = { checkbox }
  if rest and rest ~= "" then
    table.insert(new_inlines, pandoc.Str(rest))
  end
  for i = consumed + 1, #inlines do
    table.insert(new_inlines, inlines[i])
  end

  first_block.content = new_inlines
  cell.contents[1] = first_block
  return cell
end

function Table(tbl)
  local function process_row(row)
    for _, cell in ipairs(row.cells) do
      cell_to_checkbox(cell)
    end
  end

  for _, body in ipairs(tbl.bodies) do
    for _, row in ipairs(body.body) do process_row(row) end
  end
  if tbl.head and tbl.head.rows then
    for _, row in ipairs(tbl.head.rows) do process_row(row) end
  end

  return tbl
end
