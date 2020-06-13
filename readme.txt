This work is licensed under the GNU AFFERO GENERAL PUBLIC LICENSE, (c) 2020 MisterE
Coin_press_coin_press.b3d, coin_press_coin_press.png, and coin_press_coin_press_inventory.png are licensed under (CC by 4.0), (c) 2020 MisterE
https://creativecommons.org/licenses/by/4.0/

This mod would not have been possible without the help of Krock
https://forum.minetest.net/viewtopic.php?f=47&t=24907&hilit=modding+with+inventories

init.lua was adapted from furnace.lua (default:furnace)
as well as the code supplied in the forum linked above by Krock and from minetest modding book by Rubenwardy
https://minetest.org/modbook/chapters/node_metadata.html
and from lua_api.txt

This mod depends on a custom mod coins. You can make your own coins mod, just make a mod named "coins", and have it define a craft item "coins:gold_coins"

alternatively, you can edit this mod to use your server's pre-existing coins mod. Just change the depends list in mod.conf to not include [coins]
and then edit the second line of init.lua where the local variable coin_item is declared to be the itemname of the gold coins in your mod.
