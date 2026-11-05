-- Sidebar status line: replace the default file info with a key reminder.
local function hints()
  return ui.Line {
    ui.Span(" ⏎"):fg("#f9e2af"), ui.Span(" open "):fg("#9399b2"),
    ui.Span("e"):fg("#f9e2af"),  ui.Span(" vim "):fg("#9399b2"),
    ui.Span("O"):fg("#f9e2af"),  ui.Span(" app "):fg("#9399b2"),
    ui.Span("r"):fg("#f9e2af"),  ui.Span(" finder "):fg("#9399b2"),
    ui.Span("h"):fg("#f9e2af"),  ui.Span(" back "):fg("#9399b2"),
    ui.Span("~"):fg("#f9e2af"),  ui.Span(" help"):fg("#9399b2"),
  }
end
for _, id in ipairs({ 1, 2, 3 }) do Status:children_remove(id, Status.LEFT) end
for _, id in ipairs({ 4, 5, 6 }) do Status:children_remove(id, Status.RIGHT) end
Status:children_add(hints, 10, Status.LEFT)
