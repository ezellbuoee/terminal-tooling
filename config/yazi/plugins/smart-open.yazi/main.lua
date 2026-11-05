--- @sync entry
-- Enter: go into folders, otherwise open the file the smart way (text -> vim, else macOS app)
return {
  entry = function()
    local h = cx.active.current.hovered
    if not h then return end
    if h.cha.is_dir then
      ya.emit("enter", {})
    else
      ya.emit("shell", { "/Users/eolasehinde/.config/zellij/bin/zj-open smart " .. ya.quote(tostring(h.url)), orphan = true })
    end
  end,
}
