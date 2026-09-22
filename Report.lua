local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
	local restored = SVShim.account + SVShim.character
	local byGame = #SVShim.loadedByGame
	if restored == 0 and byGame > 0 then
		print(("|cff33ff99SVShim|r the game loaded all %d settings files itself this session. If you see this every login, Blizzard has fixed the bug and you can close Start-SVShim and delete the !!SVShim folder."):format(byGame))
		return
	end
	print(("|cff33ff99SVShim|r restored %d account and %d character settings files."):format(SVShim.account, SVShim.character))
	if byGame > 0 then
		print(("|cff33ff99SVShim|r the game loaded these itself: %s"):format(table.concat(SVShim.loadedByGame, ", ")))
	end
	if restored == 0 then
		print("|cff33ff99SVShim|r nothing to restore. Start Start-SVShim.cmd (in the !!SVShim folder), then /reload.")
	end
	if #SVShim.skipped > 0 then
		print(("|cff33ff99SVShim|r skipped %s: this character name exists on several realms and the realm couldn't be matched (this realm: id %s, name %s)"):format(
			table.concat(SVShim.skipped, ", "), tostring(GetRealmID and GetRealmID()), tostring(GetRealmName and GetRealmName())))
	end
end)
