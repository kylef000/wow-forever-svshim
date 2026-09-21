local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
	print(("|cff33ff99SVShim|r restored %d account and %d character settings files."):format(SVShim.account, SVShim.character))
	if SVShim.account + SVShim.character == 0 then
		print("|cff33ff99SVShim|r nothing to restore. Start Start-SVShim.cmd (in the !!SVShim folder), then /reload.")
	end
	if #SVShim.skipped > 0 then
		print(("|cff33ff99SVShim|r skipped %s: this character name exists on several realms and the realm couldn't be matched (this realm: id %s, name %s)"):format(
			table.concat(SVShim.skipped, ", "), tostring(GetRealmID and GetRealmID()), tostring(GetRealmName and GetRealmName())))
	end
end)
