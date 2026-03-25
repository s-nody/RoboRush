local M = {}

function M.aabb(ax, ay, aw, ah, bx, by, bw, bh)
  return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

--- Clamp entity inside inner rectangle (room bounds minus margin)
function M.clampToRect(x, y, w, h, minx, miny, maxx, maxy)
  if x < minx then x = minx end
  if y < miny then y = miny end
  if x + w > maxx then x = maxx - w end
  if y + h > maxy then y = maxy - h end
  return x, y
end

--- Circle-rect for pickups (optional); AABB is primary
function M.pointInRect(px, py, rx, ry, rw, rh)
  return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
end

return M
