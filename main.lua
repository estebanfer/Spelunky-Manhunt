meta.name = 'Spelunky Manhunt'
meta.version = '1.1'
meta.description = 'Spawns an angry hired hand at every level'
meta.author = 'Estebanfer'
--problems when a hh revives again with necro, and you get in or out of the necro radius
--bug when restart at first frame, also when shortcut?
reviving = false
count = 0

hh_uid = 0
hh = nil
pl_layer = 0
cycle = 0
elapsed = 0
DEFAULT_ACCELERATION = 0.032
DEFAULT_MAX_SPEED = 0.0725
function default_settings()
  hh_health = 4
  hh_ghost_check = true
  hh_revive_check = true
  hh_angry_ghost_check = false
  hh_revive_time = 3
  hh_revive_stun_time = 60
  hh_stun_start = 1
  hh_take_no_damage_check = false
  hh_speed = 1
  kill_hhs_check = false
  hh_no_corpse_revive_check = true
  gh_velocity = 4
end
default_settings()
ghost = 0
lastspos = {0, 0, 0} --last second position
lastpos = {0, 0, 0}
door_x = 0
door_y = 0
layer_flag = true
can_go_door = true
platform_nspawned = true
first_spawn = true

names = {}
for i,v in pairs(ENT_TYPE) do
  names[v] = i
end

function closest(num)
  return math.floor(num+0.5)
end

function get_blocks(floors)
  local blocks = {}
  for i, v in ipairs(floors) do
      local ent = get_entity(v)
      if type(ent.type) == 'number' then
        table.insert(blocks, v)
      elseif not (string.match(names[ent.type.id], 'PLATFORM') or string.match(names[ent.type.id], 'LADDER') or string.match(names[ent.type.id], 'DOOR') or ent.type.id == ENT_TYPE.FLOOR_VINE or ent.type.id == ENT_TYPE.FLOOR_CHAINANDBLOCKS_CHAIN) then
          table.insert(blocks, v)
      end
  end
  return blocks
end

function spawn_necro(x, y, layer)
  elapsed = 0
  local n_uid = spawn_entity(ENT_TYPE.MONS_NECROMANCER, x, y, layer, 0, 0)
  local n = get_entity(n_uid)
  n.flags = set_flag(n.flags, 4)
  n.color.a = 0.6
  if first_spawn then 
    if (state.theme == THEME.TIAMAT or state.theme == THEME.OLMEC) then
      get_entity(n_uid).stun_timer = 900
    end
    set_timeout(function()
      local nx, ny = get_position(n_uid)
      nx, ny = math.floor(nx+0.5), math.floor(ny+0.5)
      local tdfloors = get_entities_at(0, MASK.FLOOR, nx, ny-1, 0, 0.4)
      if #tdfloors == 0 or get_entity_type(tdfloors[1]) == ENT_TYPE.FLOOR_CONVEYORBELT_RIGHT or get_entity_type(tdfloors[1]) == ENT_TYPE.FLOOR_CONVEYORBELT_LEFT then
        if #tdfloors == 1 then
          kill_entity(tdfloors[1])
        end
        tfloor = spawn_entity(ENT_TYPE.FLOOR_DOOR_PLATFORM, nx, ny-1, layer, 0, 0)
      end
    end, 2)
  end
  set_timeout(function()
    get_entity(n_uid).stun_timer = 2
  end, 10)
  set_timeout(function()
    if state.theme ~= COSMIC_OCEAN then
      move_entity(n_uid, 20, 300, 0, 0)
    end
    kill_entity(n_uid)
  end, 160)
  first_spawn = false
end

function spawn_hh(x,y,layer)
  local uid = spawn_entity(ENT_TYPE.ITEM_COFFIN, x, y, layer, 0, 0)
  local ent = get_entity(uid)
  set_contents(uid, ENT_TYPE.CHAR_HIREDHAND) --just in case is another char
  ent.flags = set_flag(ent.flags, 5)
  ent.flags = set_flag(ent.flags, 10)
  ent.flags = set_flag(ent.flags, 1)
  set_timeout(function()
    local x, y, layer = get_position(players[1].uid)
    x, y = math.floor(x+0.5), math.floor(y+0.5)
    local ent = get_entities_at(ENT_TYPE.ITEM_SKULL, 0, x, y+0.2,layer, 0.2)
    if ent[1] ~= nil then
      kill_entity(ent[1])
    end
  end, 1)
  kill_entity(uid)
end

function get_new_hh()
  local thhs = get_entities_by_type(ENT_TYPE.CHAR_HIREDHAND)
  local hh_uid, hh --not tested
  if #thhs == 1 then
    hh_uid = thhs[1]
  else
    for i,v in ipairs(thhs) do
      if get_entity(v).stun_timer ~= 0 then
        hh_uid = v
      end
    end
  end
  hh = get_entity(hh_uid)
  return hh_uid, hh
end

function spawn_new_hh_apart()
  local tospawn_x, tospawn_y
  if state.theme == THEME.OLMEC then
    tospawn_x, tospawn_y = 4, 118
  elseif state.theme == THEME.HUNDUN then
    local doors = get_entities_by_type(ENT_TYPE.FLOOR_DOOR_EXIT)
    tospawn_x, tospawn_y = get_position(doors[1])
  else
    tospawn_x, tospawn_y = spawn_x, spawn_y
  end
  if platform_nspawned then
    --spawn_entity(ENT_TYPE.FLOOR_PLATFORM, tospawn_x, tospawn_y, 0, 0, 0)
    spawn_entity(ENT_TYPE.FLOOR_DOOR_PLATFORM, tospawn_x+0.4, tospawn_y, 0, 0, 0)
    platform_nspawned = false
  end
  spawn_hh(tospawn_x, tospawn_y+1.5, 0)
  spawn_hh(tospawn_x, tospawn_y+1.5, 0)
  set_timeout(function()
    local px, py, pl = get_position(players[1].uid)
    thh_uid, thh = get_new_hh()
    thh.flags = set_flag(thh.flags, 4)
    thh.health = 1
    thh.stun_timer = 0
    thh.airtime = 40
    thh.color.a = 0
    thh2_uid, thh2 = get_new_hh()
    --thh.stun_timer = 2
    thh2.flags = set_flag(thh2.flags, 1)
    thh2.flags = set_flag(thh2.flags, 4)
    --thh2.flags = set_flag(thh2.flags, 10)
    move_entity(thh2_uid, px, py, 0, 0)
    --steal_input(thh2_uid)
    set_timeout(function() move_entity(thh2_uid, tospawn_x, tospawn_y+1.2, 0, 0); steal_input(thh2_uid); send_input(thh2_uid, 256) end, 4)
    set_timeout(function() send_input(thh2_uid, 0) end, 5)
    local ents = get_blocks(get_entities_at(0, MASK.FLOOR, tospawn_x+1, tospawn_y+1, LAYER.FRONT, 0.5))
    for i, v in ipairs(ents) do
      kill_entity(v)
    end
    spawn_necro(tospawn_x+0.8, tospawn_y+1.1, 0)
    hhs = get_entities_by_type(ENT_TYPE.CHAR_HIREDHAND)
    toClear = set_interval(revived_hh_func, 1)
    reviving = false
  end, 1)
end

function layer_changed()
  local time = math.floor(distance(players[1].uid, hh_uid) * 15)
  can_go_door = false
  set_timeout(function() can_go_door = true end, time)
  door_x, door_y = get_position(players[1].uid)
end

function goto_door()
  if hh.health == 0 and not hh_revive_check then
    return
  end
  local px, py, pl = get_position(players[1].uid)
  local hhx, hhy, hhl = get_position(hh_uid)
  if hh.stun_timer == 0 and hh.state ~= 12 and #get_entities_at(0, MASK.LAVA, door_x, door_y, hhl, 0.5) == 0 and ghost == 0 then
    if hhx ~= door_x then
      move_entity(hh_uid, door_x, door_y, 0, 0)
    end
    steal_input(hh_uid)
    send_input(hh_uid, 32)
  end
end

function revived_hh_func()
  elapsed = elapsed + 1
  if hh ~= nil or players[1] == nil then 
    clear_callback(toClear)
    return
  end
  local thhs = get_entities_by_type(ENT_TYPE.CHAR_HIREDHAND)
  if hhs == nil then hhs = {} end
  local px, py, pl = get_position(players[1].uid)
  local hh_num = nil
  local diff = 0
  if #thhs < #hhs then
    for i, v in ipairs(thhs) do -- in case a hh dies in the exact frame the angry hh revives
      hh_num = i
      for i1, v1 in ipairs(hhs) do
        if v == v1 then hh_num = nil end
      end
    end
    if hh_num == nil then
      hhs = thhs
    end
    --messpect'diff:', diff, '#thhs:', #thhs)
  elseif #thhs > #hhs then
    diff = #thhs - #hhs
  end
  for i, v in ipairs(hhs) do
    if v ~= thhs[i] then hh_num = i+diff end
    --messpect(v)
  end
  if hh_num ~= nil then --hhs[#hhs] then
    hhs = nil
    if kill_hhs_check then --kill hhs and coffins
      for i, v in ipairs(thhs) do
        if i ~= hh_num and v ~= thh2_uid then kill_entity(v) end
      end
      local coffins = get_entities_by_type(ENT_TYPE.ITEM_COFFIN)
      for i, v in ipairs(coffins) do
        local cof = get_entity(v)
        cof.flags = set_flag(cof.flags, 5)
        cof.flags = set_flag(cof.flags, 10)
        move_entity(v, 0, 300, 0, 0)
      end
    end
    hh_uid = thhs[hh_num]
    hh = get_entity(hh_uid)
    if hh_take_no_damage_check then hh.flags = set_flag(hh.flags, 6) end --take no damage
    hh.flags = set_flag(hh.flags, 4)
    hh.flags = clr_flag(hh.flags, 5) -- new
    hh.flags = clr_flag(hh.flags, 10) -- new
    hh.color.r = 0.9
    hh.color.g = 0.5
    hh.color.b = 0.5
    hh.stun_timer = hh_stun_start*60
    local hht = get_type(ENT_TYPE.CHAR_HIREDHAND)
    hht.acceleration = DEFAULT_ACCELERATION*hh_speed
    hht.max_speed = DEFAULT_MAX_SPEED*hh_speed
    set_timeout(function() hh.flags = clr_flag(hh.flags, 4) end, hh_stun_start*60)
    hh.health = hh_health
    if thh2_uid ~= nil then
      return_input(thh2_uid)
      if state.theme ~= COSMIC_OCEAN then
        move_entity(thh2_uid, 20, 300, 0, 0)
        move_entity(hh_uid, 20, 300, 0, 0)
      end
      kill_entity(thh2_uid)
      hh.flags = set_flag(hh.flags, 5)
      hh.flags = set_flag(hh.flags, 10)
      hh.stun_timer = hh_revive_time*60-1
      set_timeout(function()
        move_entity(hh_uid, lastpos[1], lastpos[2], 0, 0)
        spawn_ghost()
        to_ghost_intv = set_interval(to_ghost, 60)
      end, hh_revive_time*60)--]
      --move_entity(hh_uid, lastpos[1], lastpos[2], 0, 0)
      --spawn_ghost()
      --to_ghost_intv = set_interval(to_ghost, 60)
    end
    clear_callback(toClear)
  end
  if elapsed > 200 then
    kill_entity(thh_uid)
    if thh2_uid ~= nil then
      return_input(thh2_uid)
      if state.theme ~= COSMIC_OCEAN then
        move_entity(thh2_uid, 20, 300, 0, 0)
      end
      kill_entity(thh2_uid)
    end
    set_timeout(function()
      spawn_new_hh_apart()
    end, 1 )
    elapsed = 0
    clear_callback(toClear)
  end
end

set_callback(function()
  sacd = false
  thh2 = nil
  thh2_uid = nil
  first_spawn = true
  platform_nspawned = true
  count = 0
  hh = nil
  hh_uid = 0
  door_x = 0
  door_y = 0
  ghost = 0
  can_go_door = false
  layer_flag = true
  reviving = false
  if to_ghost_intv ~= nil then clear_callback(to_ghost_intv) end
  if toClear ~= nil then clear_callback(toClear) end
  set_timeout(function()
    to_ghost_intv = set_interval(to_ghost, 60) 
    set_interval(function()
      if ghost ~= 0 then ghostf() end
      if players[1] == nil or hh == nil then return end
      local hhx, hhy, hhl = get_position(hh_uid)
      if hhy < 0 then
        move_entity(hh_uid, hhx, 2, 0, 0)
        spawn_ghost()
      end
      if get_entity_type(hh_uid) == ENT_TYPE.CHAR_HIREDHAND and hhy < 200 then
        lastpos[1], lastpos[2], lastpos[3] = get_position(hh_uid)
      end
      local px, py, pl = get_position(players[1].uid)
      if players[1].state == 21 and pl_layer ~= pl then
        if layer_flag and hhl ~= pl then
          layer_changed()
          layer_flag = false
        end
      else layer_flag = true end
      if hhl ~= pl and can_go_door and ghost == 0 and not test_flag(hh.flags, 29) and cycle == 0 then
        goto_door()
      else
        return_input(hh_uid)
      end
      if cycle >= 5 then
        cycle = 0
      else
        cycle = cycle + 1
      end
      pl_layer = pl
      local hhvx, hhvy = get_velocity(hh_uid)
      local ent = get_entity(hh.standing_on_uid)
      if ent ~= nil then
        if type(ent.type) == 'number' then
          ent = ent.type
        else
          ent = ent.type.id
        end
      end
      if ent == ENT_TYPE.FLOOR_ALTAR and (hh.state == CHAR_STATE.STUNNED or hh.state == CHAR_STATE.DYING) and hhvy == 0 and math.abs(hhvx) < 0.1 then
        if sacd then
          move_entity(hh_uid, hhx, hhy, math.random()/2-0.25, math.random()/10+0.15)
        else
          set_timeout(function ()
            sacd = true
          end, 90)
        end
      end
    end, 1)
  end, 210)
  local x, y, layer = get_position(players[1].uid)
  if players[1]:topmost_mount().uid ~= players[1].uid then
    y = y - 0.5
  end
  spawn_x = closest(x)
  spawn_y = closest(y)
  steal_input(players[1].uid)
  send_input(players[1].uid, 256)
  spawn_hh(x, y, layer)
  spawn_necro(x+1,y+1,layer)
  set_timeout(function() send_input(players[1].uid, 0) end, 1)
  set_timeout(function()
    return_input(players[1].uid)
  end, 60)
    if (hh_uid == 0) then 
      thh_uid, thh = get_new_hh()
    else
      thh = get_entity(hh_uid)
    end
    lastspos[1], lastspos[2], lastspos[3] = get_position(thh_uid)
    lastpos[1], lastpos[2], lastpos[3] = get_position(thh_uid)
    thh.health = 1
    thh.airtime = 40
    thh.flags = set_flag(thh.flags, 4)
    hhs = get_entities_by_type(ENT_TYPE.CHAR_HIREDHAND)
    toClear = set_interval(revived_hh_func, 1)
end, ON.LEVEL)

set_callback(function()
  clear_callback(to_ghost_intv)
  ghost = 0
end, ON.TRANSITION)

function spawn_ghost()
  local g
  if hh_uid ~= 0 then
    hh.flags = set_flag(hh.flags, 1)
    hh.stun_timer = 2
    if state.theme == THEME.COSMIC_OCEAN then
      move_entity(hh_uid, spawn_x, spawn_y+0.2, 0, 0, 0)
    else
      move_entity(hh_uid, 0, 300, 0, 0, 0)
    end
    hh.flags = set_flag(hh.flags, 5)
    hh.flags = set_flag(hh.flags, 10)
    hh.more_flags = set_flag(hh.more_flags, 16)
    ghost = spawn_entity(ENT_TYPE.MONS_GHOST_SMALL_SAD, lastpos[1], lastpos[2], lastpos[3], 0, 0)
    g = get_entity(ghost)
    g.flags = set_flag(g.flags, 5)
    g.color.g = 0.9
    g.color.b = 0.4
  else
    ghost = spawn_entity(ENT_TYPE.MONS_GHOST_SMALL_ANGRY, lastpos[1], lastpos[2]-0.5, lastpos[3], 0, 0)
    g = get_entity(ghost)
    g.flags = set_flag(g.flags, 5)
    g.velocity_multiplier = 0.8
    g.color.g = 0.5
    g.color.b = 0.2
    set_timeout(function()
      g.flags = clr_flag(g.flags, 5)
      g.color.g = 0
      g.color.b = 0
    end, 60)
  end
  g.color.r = 1
end

function to_ghost()
  if players[1] == nil then return end
  if get_entity_type(hh_uid) ~= ENT_TYPE.CHAR_HIREDHAND then
    if hh_uid == 0 then return end
    clear_callback(to_ghost_intv)
    hh = nil
    hh_uid = 0
    if hh_angry_ghost_check and hh_revive_check then set_timeout(spawn_ghost, 60) end
    if hh_no_corpse_revive_check and hh_revive_check then spawn_new_hh_apart() end--set_timeout(spawn_ghost, 60) end
    return
  end
  local hhx, hhy, hhl = get_position(hh_uid)
  local px, py, pl = get_position(players[1].uid)
  if hh_ghost_check and ghost == 0 and ( math.abs(py-hhy) > 4 or distance(players[1].uid, hh_uid) > 8 ) and ( math.abs(py-hhy) > 4 or math.abs(lastspos[1]-hhx) < 2 ) and math.abs(lastspos[2]-hhy) < 2 and hhl == pl then --distance(players[1].uid, hh_uid) > 8 and (hh_revive_check or not test_flag(hh.flags, 29))
    if ( not test_flag(hh.flags, 29) and count > 2 ) then --or ( test_flag(hh.flags, 29) and count >= hh_revive_time ) then
      spawn_ghost()
    end
    count = count + 1
  else count = 0 end
  hh.color.g = 0.5+math.min(count/10, 0.4)
  hh.color.b = 0.5+math.min(count/10, 0.4)
  --extra
  lastspos[1] = hhx
  lastspos[2] = hhy
  lastspos[3] = hhl
  if hh_revive_check and test_flag(hh.flags, 29) and not reviving then
    reviving = true
    set_timeout(function()
      if hh == nil then
        return
      end
      count = 1
      local hhx, hhy, hhl = get_position(hh_uid)
      hh.flags = clr_flag(hh.flags, 29)
      hh.health = hh_health
      if #get_entities_at(0, MASK.LAVA, hhx, hhy, hhl, 0.8) == 0 then
        hh.stun_timer = hh_revive_stun_time
      else
        spawn_ghost()
      end
      reviving = false
    end, hh_revive_time*60)
  end
end

function ghostf()
  local gh = get_entity(ghost)
  if players[1] == nil or hh_uid == 0 then
    if get_entity_type(ghost) == ENT_TYPE.MONS_GHOST_SMALL_SAD then
      kill_entity(ghost)
      ghost = 0
    end
    return
  end
  if get_entity_type(ghost) ~= ENT_TYPE.MONS_GHOST_SMALL_SAD and get_entity_type(ghost) ~= ENT_TYPE.MONS_GHOST_SMALL_ANGRY then return end
  local gh_vel = distance(players[1].uid, ghost) / 40 + 1
  gh.velocity_multiplier = gh_vel*gh_vel*(gh_velocity/2)
  local px, py, pl = get_position(players[1].uid)
  local gx, gy, gl = get_position(ghost)
  local hhx, hhy, hhl = get_position(hh_uid)
  local ents = get_entities_at(0, MASK.FLOOR, gx, gy, gl, 0.7)
  ents = get_blocks(ents)
  if math.abs(px-gx) < 3.5 and math.abs(py-gy) < 2 and gl == hhl and #ents == 0 and #get_entities_at(0, MASK.ACTIVEFLOOR, gx, gy, gl, 0.7) == 0 and #get_entities_at(0, MASK.LAVA, gx, gy, gl, 0.8) == 0 or pl ~= hhl then
    if pl == hhl then
      move_entity(hh_uid, gx, gy, 0, 0)
    else
      move_entity(hh_uid, px, py, 0, 0)
    end
    hh.flags = clr_flag(hh.flags, 5)
    hh.flags = clr_flag(hh.flags, 10)
    hh.flags = clr_flag(hh.flags, 4)
    hh.flags = clr_flag(hh.flags, 1)
    hh.more_flags = clr_flag(hh.more_flags, 16)
    hh.stun_timer = 0
    hh.health = hh_health
    hh.color.g = 0.5+count/10
    hh.color.b = 0.5
    return_input(hh_uid)
    kill_entity(ghost)
    ghost = 0
    return
  end
  local close_hhs = get_entities_at(ENT_TYPE.CHAR_HIREDHAND, 0, gx, gy, gl, 0.9)
  if close_hhs[1] ~= nil and close_hhs[1] ~= hh_uid then kill_entity(close_hhs[1]) end
end

--GUI
widgetOpen = true
register_option_button("open", "Edit additional features", function()
    widgetOpen = true
end)

set_callback(function(draw_ctx)
  if widgetOpen then
    widgetOpen = draw_ctx:window("Spelunky Manhunt additional features and settings", -0.2, 1, 1, 0.9, true, function()
      hh_health = draw_ctx:win_slider_int("HH health", hh_health, 1, 20)
      draw_ctx:win_sameline(0, -2)
      if draw_ctx:win_button("Reset settings") then
        default_settings()
      end
      hh_stun_start = draw_ctx:win_slider_int("Extra seconds a HH is stunned at start", hh_stun_start, 0, 10)
      hh_ghost_check = draw_ctx:win_check("Hired hand can become a ghost when is far", hh_ghost_check)
      hh_revive_check = draw_ctx:win_check("Hired hand can revive", hh_revive_check)
      hh_angry_ghost_check = draw_ctx:win_check("Hired hand can become angry ghost when no corpse", hh_angry_ghost_check)
      hh_no_corpse_revive_check = draw_ctx:win_check("Hired hand revives even when no corpse", hh_no_corpse_revive_check)
      hh_angry_ghost_check = hh_revive_check and hh_angry_ghost_check
      hh_no_corpse_revive_check = hh_revive_check and hh_no_corpse_revive_check
      hh_angry_ghost_check = hh_angry_ghost_check and not hh_no_corpse_revive_check
      hh_revive_time = draw_ctx:win_slider_int("Seconds for a hired hand to revive", hh_revive_time, 0, 60)
      gh_velocity = draw_ctx:win_slider_int("Hired hand ghost velocity", gh_velocity, 2, 10)
      hh_revive_stun_time = draw_ctx:win_slider_int("Ticks a hh is stunned after reviving 60=1s", hh_revive_stun_time, 2, 300)
      hh_speed = draw_ctx:win_slider_float("Hired hands speed (of all hhs)", hh_speed, 0.01, 4.0)
      hh_take_no_damage_check = draw_ctx:win_check("Hired hand can't take damage", hh_take_no_damage_check)
      kill_hhs_check = draw_ctx:win_check("Kill all other hired hands", kill_hhs_check)
    end)
  end  
end, ON.GUIFRAME)


