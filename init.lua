--coin item to use as output
local coin_item = "coins:gold_coins"
--number of coins to output per gold ingot
local coins_per_ingot = 8
--time it takes to press out 1 coin
local press_time = 1

local function get_coin_press_formspec(pos,gold_percent)
  local meta = minetest.get_meta(pos)
  local help = meta:get_string("help")
  local protect = meta:get_int("protect")
  local pbutton = ""
  if protect == 1 then
    pbutton = "Allow others to use"
  else
    pbutton = "Prevent others from using (if protected)"
  end
  local formspectbl ={
    "size[8,8]",
    "label[0.5,1.5;"..(help).."]",
    "list[context;input;1,2;1,1;]",
    "image[3.5,2;1,1;default_steel_ingot.png^[lowpart:"..(gold_percent)..":default_gold_ingot.png]",
    "list[context;output;6,2;1,1;]",
    "button[3,3;2,1;stamp;FEED/STAMP]",
    "list[current_player;main;0,4;8,4;]",
    "button[2,0;4,1;pbutton;"..(pbutton).."]"
  }
  if meta:get_int("protect") == 0 then
    formspectbl[#formspectbl +1] = "label[0,1;WARNING: Unprotected]"
  end
  local formspec = table.concat(formspectbl,"")
  return formspec
end
------------------------------------
local function can_dig(pos, player)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()
	return inv:is_empty("input") and inv:is_empty("output") --TODO: and gold_percent = 0
end
------------------------------------
--permits a player who owns the protection to put gold ingots into the input slot, and prevents them from putting anything into the output slot
local function allow_metadata_inventory_put(pos, listname, index, stack, player)
  local meta = minetest.get_meta(pos)

  if meta:get_int("protect") == 1 then
    if (minetest.is_protected(pos, player:get_player_name())) then
      return 0
    end
  end
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if listname == "input" then
		if stack:get_name() == "default:gold_ingot" then
			if inv:is_empty("input") then --TODO: and not(has gold_percent = 0)
				--meta:set_string("infotext", S("Coin Press is Empty"))
			end
			return stack:get_count() --returns the number of gold ingots that will be placed in the machine
		else
			return 0
		end

	elseif listname == "output" then -- you cant place things into the output slot
		return 0
	end
end

------------------------------------
--[[ I don't think I need this, since there is only 1 inventory location
local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end --]]
---------------------------------------
-- if taking from an inventory position, you can only do it if you awn the protection or its not protected. If allowed, returns the number of items to be taken
local function allow_metadata_inventory_take(pos, listname, index, stack, player)
  local meta = minetest.get_meta(pos)

  --minetest.chat_send_all(dump(meta:get_int("protect"))) --debug
  if meta:get_int("protect") == 1 then
  	if (minetest.is_protected(pos, player:get_player_name())) then
  		return 0
  	end
  end
	return stack:get_count()
end
----------------------------------------
-- Coin_press timer
local function coin_press_node_timer(pos)
  --initialize metadata
  local meta = minetest.get_meta(pos)
  local gold_percent = meta:get_float("gold_percent")
  local inv = meta:get_inventory()
  local input_list = inv:get_list("input")
  local output_list = inv:get_list("output")
  local output_stack = output_list[1] -- get the output stack (for gold coins)
  local input_stack = input_list[1] -- get the input stack (for gold)
  meta:set_string("help","Press The Button To Stamp Coin")


  if gold_percent > 0 then --check if there is gold in machine.(as opposed to just in the input slot) (gold_percent >0)
    --if there is gold in the machine, we can make a coin...
    --then check if there is room in the output inventory for coins
    if output_stack:is_empty() or ((output_stack:get_name() == coin_item) and (output_stack:get_free_space() > 0 )) then
      inv:add_item("output",coin_item)  --put 1 coin into the output inventory
      meta:set_float("gold_percent",gold_percent - (100/coins_per_ingot))  --remove one percentage of the gold per coins_per_gold variable from the gold_percentage
      gold_percent = gold_percent - (100/coins_per_ingot) --update our local var
    else --If there isnt room in the output inv for coins,
      meta:set_string("help","Coin Slot Full")

    end
  else -- if there is no gold "in the machine", then,
    --check if there is a gold ingot in the input inventory
    if input_stack:get_name() == "default:gold_ingot" then -- check if there is at least 1 gold ingot in the input inventory
      if input_stack:get_count() == 1 then -- if there is only 1 gold ingot in the stack then
        inv:set_stack("input", 1, "") --delete the input stack, making it empty
      else --if there is more than 1 gold ingot in the input stacks then
        inv:remove_item("input", "default:gold_ingot") --remove 1 gold ingot
      end
      meta:set_float("gold_percent", 100.00) -- set the gold percent to 100
      gold_percent = 100
      --then check if there is room in the output inventory for coins
      if output_stack:is_empty() or ((output_stack:get_name() == coin_item) and (output_stack:get_free_space() > 0 )) then
        inv:add_item("output",coin_item)  --put 1 coin into the output inventory
        meta:set_float("gold_percent", gold_percent - (100/coins_per_ingot))  --remove one percentage of the gold per coins_per_gold variable from the gold_percentage
        gold_percent = gold_percent - (100/coins_per_ingot) -- update our local var
      else --If there isnt room in the output inv for coins,
        meta:set_string("help","Coin Slot Full")

      end
    else -- if there is no gold ingot in the input inventory, then
      meta:set_string("help","Insert Gold Ingot")
    end
  end
  meta:set_string("formspec",get_coin_press_formspec(pos,meta:get_float("gold_percent")))

end






minetest.register_node('coin_press:coin_press', {
   description = 'Coin Press',
   drawtype = 'mesh',
   mesh = 'coin_press_coin_press.b3d',
   tiles = {name='coin_press_coin_press.png'},
   inventory_image = 'coin_press_coin_press_inventory.png',
   wield_image = "coin_press_coin_press_inventory.png",
   groups = {choppy=2},
   paramtype = 'light',
   paramtype2 = 'facedir',
   selection_box = {
      type = 'fixed',
      fixed = {-.5, -.5, -.14, .5, .5, .49},
      },
   collision_box = {
      type = 'fixed',
      fixed = {-.5, -.5, -.14, .5, .5, .49},
      },
    on_construct = function(pos)
      local meta = minetest.get_meta(pos)
      local inv = meta:get_inventory()


      inv:set_size("input",1)
      inv:set_size("output",1)
      meta:set_float("gold_percent",0)
      meta:set_int("protect",1)
      meta:set_string("help","Insert Gold Ingot")


      meta:set_string("formspec",get_coin_press_formspec(pos,0))
      --the key "formspec" is a special key that sets the meta's formspec
    end,
    on_receive_fields = function(pos, formname, fields, player)
      local meta = minetest.get_meta(pos)


      if meta:get_int("protect") == 1 then
        if (minetest.is_protected(pos, player:get_player_name())) then
          return 0
        end
      end

      if fields.stamp then
        minetest.get_node_timer(pos):start(press_time)
        --start the timer
      end
      if fields.pbutton then

        local gold_percent = meta:get_float("gold_percent")
        if not((minetest.is_protected(pos, player:get_player_name()))) then
          if meta:get_int("protect") == 1 then
            meta:set_int("protect",0)
          else
            meta:set_int("protect",1)
          end
          meta:set_string("formspec",get_coin_press_formspec(pos,gold_percent))
        end
      end
    end,
    on_timer = coin_press_node_timer,
    allow_metadata_inventory_put = allow_metadata_inventory_put,
    allow_metadata_inventory_take = allow_metadata_inventory_take,
    can_dig = can_dig,
    on_blast = function(pos)
      local drops = {}
      default.get_inventory_drops(pos, "input", drops)
      default.get_inventory_drops(pos, "output", drops)
      drops[#drops+1] = "coin_press:coin_press"
      minetest.remove_node(pos)
      return drops
    end,



})


if minetest.get_modpath("basic_materials") and minetest.get_modpath("stairs")then

  minetest.register_craft({
	output = "coin_press:coin_press",
	recipe = {
  		{"default:steelblock", "basic_materials:steel_strip", "default:steelblock"},
  		{"stairs:slab_glass", "basic_materials:gear_steel", "stairs:slab_glass"},
  		{"default:steelblock", "default:mese_crystal",  "default:steelblock"}
  	}
  })

else
  minetest.register_craft({
  output = "coin_press:coin_press",
  recipe = {
      {"default:steelblock", "default:obsidian_glass", "default:steelblock"},
      {"default:obsidian_glass", "default:steelblock", "default:obsidian_glass"},
      {"default:steelblock", "default:diamond",  "default:steelblock"}
    }
  })
end
