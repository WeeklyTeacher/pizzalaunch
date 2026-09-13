local loadModule = require("./support/LoadModule")
local roblox = require("@lune/roblox")
local config = loadModule("src/shared/MasteryConfig.luau")
local Cosmetics = loadModule("src/server/ProfileCosmetics.luau", {
	game={GetService=function()return {Shared={MasteryConfig="mastery"}}end},
	require=function(name)assert(name=="mastery");return config end,
})
local parent=roblox.Instance.new("Folder")
local function character()
	local model=roblox.Instance.new("Model");model.Parent=parent
	local head=roblox.Instance.new("Part");head.Name="Head";head.Parent=model
	return model
end
local player={Parent=parent,Character=character()}
local unknown=roblox.Instance.new("BillboardGui");unknown.Name="EarnedChefNameplate";unknown.Parent=player.Character.Head
assert(not Cosmetics.apply(player,{equipped="gold",earnedCosmetics={plain=true}},false))
assert(unknown.Parent==player.Character.Head, "Never replace an unknown namesake")
local snapshot={status="loading",equipped="plain",earnedCosmetics={plain=true}}
assert(not Cosmetics.apply(player,snapshot,false), "Unknown history cannot display a default earned style")
snapshot.status="memory"
assert(Cosmetics.apply(player,snapshot,false))
local first
for _,gui in player.Character.Head:GetChildren() do if gui~=unknown then first=gui end end
assert(first.Enabled and first.Style.Text=="Neighborhood Chef" and not first.AlwaysOnTop)
assert(Cosmetics.apply(player,snapshot,true) and not first.Enabled)
assert(#player.Character.Head:GetChildren()==2, "Repeated application cannot duplicate owned nameplates")
snapshot.equipped="basil";snapshot.earnedCosmetics.basil=true
assert(Cosmetics.apply(player,snapshot,false) and first.Enabled and first.Style.Text=="Basil Chef")
local oldHead=player.Character.Head
player.Character=character()
assert(Cosmetics.apply(player,snapshot,false) and first.Parent==nil and unknown.Parent==oldHead)
assert(#player.Character.Head:GetChildren()==1)
local owned=player.Character.Head:GetChildren()[1]
Cosmetics.clear(player);Cosmetics.clear(player)
assert(owned.Parent==nil and unknown.Parent==oldHead)
assert(player.Character.Head.CanCollide, "Appearance must not change avatar physics")
print("PASS: earned-only bounded nameplate, mount hiding, rejoin identity, idempotent cleanup and unknown-object preservation")
