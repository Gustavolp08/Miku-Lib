local httpService = game:GetService('HttpService')
local ThemeManager = {} do
	ThemeManager.Folder = 'LinoriaLibSettings'
	-- if not isfolder(ThemeManager.Folder) then makefolder(ThemeManager.Folder) end

	ThemeManager.Library = nil
	ThemeManager.BuiltInThemes = {
		['Miku'] = { 1, httpService:JSONDecode('{"FontColor":"e8fffd","MainColor":"12222a","AccentColor":"39c5bb","BackgroundColor":"0b161b","OutlineColor":"214e56","SecondaryColor":"ff86b9"}') },
		['Miku Night'] = { 2, httpService:JSONDecode('{"FontColor":"eafcff","MainColor":"141a30","AccentColor":"46d9d0","BackgroundColor":"0c1022","OutlineColor":"2a3566","SecondaryColor":"ff6fb0"}') },
		['Sakura Miku'] = { 3, httpService:JSONDecode('{"FontColor":"fff0f7","MainColor":"2a1a26","AccentColor":"ff8fc0","BackgroundColor":"1f121b","OutlineColor":"5a3149","SecondaryColor":"39c5bb"}') },
		['World Is Mine'] = { 4, httpService:JSONDecode('{"FontColor":"fff4f8","MainColor":"2a1620","AccentColor":"ff5c9a","BackgroundColor":"1e0f17","OutlineColor":"5c2a42","SecondaryColor":"ffd36b"}') },
		['Snow Miku'] = { 5, httpService:JSONDecode('{"FontColor":"f2fbff","MainColor":"1a2b3d","AccentColor":"8fd8ff","BackgroundColor":"121f2e","OutlineColor":"35506b","SecondaryColor":"b9a8ff"}') },
		['Magical Mirai'] = { 6, httpService:JSONDecode('{"FontColor":"f1fffe","MainColor":"16262e","AccentColor":"5ee6dc","BackgroundColor":"0d1a20","OutlineColor":"27555d","SecondaryColor":"ffb3d9"}') },
		['Default'] = { 7, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1c1c1c","AccentColor":"0055ff","BackgroundColor":"141414","OutlineColor":"323232","SecondaryColor":"7aa2ff"}') },
		['BBot'] = { 8, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1e1e","AccentColor":"7e48a3","BackgroundColor":"232323","OutlineColor":"141414","SecondaryColor":"c28bf0"}') },
		['Fatality'] = { 9, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1842","AccentColor":"c50754","BackgroundColor":"191335","OutlineColor":"3c355d","SecondaryColor":"ff5c9a"}') },
		['Jester'] = { 10, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"db4467","BackgroundColor":"1c1c1c","OutlineColor":"373737","SecondaryColor":"ff8aa5"}') },
		['Mint'] = { 11, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"3db488","BackgroundColor":"1c1c1c","OutlineColor":"373737","SecondaryColor":"8ff0c7"}') },
		['Tokyo Night'] = { 12, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"191925","AccentColor":"6759b3","BackgroundColor":"16161f","OutlineColor":"323232","SecondaryColor":"9d8fff"}') },
		['Ubuntu'] = { 13, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"3e3e3e","AccentColor":"e2581e","BackgroundColor":"323232","OutlineColor":"191919","SecondaryColor":"ff9a63"}') },
		['Quartz'] = { 14, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"232330","AccentColor":"426e87","BackgroundColor":"1d1b26","OutlineColor":"27232f","SecondaryColor":"78b7d6"}') },
	}

	-- Only these keys are ever read from a theme. Custom themes are user-editable JSON files, and the old code
	-- wrote every key it found straight into the Library table (a key like "Registry" would break the whole UI).
	local THEME_FIELDS = { "FontColor", "MainColor", "AccentColor", "SecondaryColor", "BackgroundColor", "OutlineColor" }

	-- Accepts "rrggbb" or "#rrggbb" and returns nil instead of throwing on garbage.
	local function ParseColor(col)
		if type(col) ~= 'string' then
			return nil
		end

		local ok, color = pcall(Color3.fromHex, col)
		return ok and color or nil
	end

	function ThemeManager:ApplyTheme(theme)
		if type(theme) ~= 'string' or theme == '' then return end

		local customThemeData = self:GetCustomTheme(theme)
		local data = customThemeData or self.BuiltInThemes[theme]

		if not data then return end

		-- custom themes are just regular dictionaries instead of an array with { index, dictionary }

		local scheme = customThemeData or data[2]

		-- Setting each picker fires its OnChanged -> ThemeUpdate, which re-skins the whole registry.
		-- Doing that 6 times per theme switch is wasteful, so updates are held back and run once at the end.
		self.Applying = true

		for _, idx in next, THEME_FIELDS do
			local color = ParseColor(scheme[idx])

			if color then
				self.Library[idx] = color

				if Options[idx] then
					Options[idx]:SetValueRGB(color)
				end
			end
		end

		self.Applying = false

		self:ThemeUpdate()
	end

	function ThemeManager:ThemeUpdate()
		if self.Applying then return end

		-- This allows us to force apply themes without loading the themes tab :)
		local options = THEME_FIELDS
		for i, field in next, options do
			if Options and Options[field] then
				self.Library[field] = Options[field].Value
			end
		end

		self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor);
		self.Library:UpdateColorsUsingRegistry()
	end

	function ThemeManager:LoadDefault()		
		local theme = 'Miku'
		local content = isfile(self.Folder .. '/themes/default.txt') and readfile(self.Folder .. '/themes/default.txt')

		local isDefault = true
		if content then
			if self.BuiltInThemes[content] then
				theme = content
			elseif self:GetCustomTheme(content) then
				theme = content
				isDefault = false;
			end
		elseif self.BuiltInThemes[self.DefaultTheme] then
		 	theme = self.DefaultTheme
		end

		if isDefault then
			Options.ThemeManager_ThemeList:SetValue(theme)
		else
			self:ApplyTheme(theme)
		end
	end

	function ThemeManager:SaveDefault(theme)
		writefile(self.Folder .. '/themes/default.txt', theme)
	end

	function ThemeManager:CreateThemeManager(groupbox)
		groupbox:AddLabel('Background color'):AddColorPicker('BackgroundColor', { Default = self.Library.BackgroundColor });
		groupbox:AddLabel('Main color')	:AddColorPicker('MainColor', { Default = self.Library.MainColor });
		groupbox:AddLabel('Accent color (teal)'):AddColorPicker('AccentColor', { Default = self.Library.AccentColor });
		groupbox:AddLabel('Secondary color (pink)'):AddColorPicker('SecondaryColor', { Default = self.Library.SecondaryColor });
		groupbox:AddLabel('Outline color'):AddColorPicker('OutlineColor', { Default = self.Library.OutlineColor });
		groupbox:AddLabel('Font color')	:AddColorPicker('FontColor', { Default = self.Library.FontColor });

		local ThemesArray = {}
		for Name, Theme in next, self.BuiltInThemes do
			table.insert(ThemesArray, Name)
		end

		table.sort(ThemesArray, function(a, b) return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1] end)

		groupbox:AddDivider()
		groupbox:AddDropdown('ThemeManager_ThemeList', { Text = 'Theme list', Values = ThemesArray, Default = 1 })

		groupbox:AddButton('Set as default', function()
			self:SaveDefault(Options.ThemeManager_ThemeList.Value)
			self.Library:Notify(string.format('Set default theme to %q', Options.ThemeManager_ThemeList.Value))
		end)

		Options.ThemeManager_ThemeList:OnChanged(function()
			self:ApplyTheme(Options.ThemeManager_ThemeList.Value)
		end)

		groupbox:AddDivider()
		groupbox:AddInput('ThemeManager_CustomThemeName', { Text = 'Custom theme name' })
		groupbox:AddDropdown('ThemeManager_CustomThemeList', { Text = 'Custom themes', Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 })
		groupbox:AddDivider()
		
		groupbox:AddButton('Save theme', function()
			if not self:SaveCustomTheme(Options.ThemeManager_CustomThemeName.Value) then
				return
			end

			Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			Options.ThemeManager_CustomThemeList:SetValue(nil)
		end):AddButton('Load theme', function()
			local name = Options.ThemeManager_CustomThemeList.Value

			if not name or name == '' then
				return self.Library:Notify('Select a custom theme first', 2)
			end

			self:ApplyTheme(name)
		end)

		groupbox:AddButton('Refresh list', function()
			Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			Options.ThemeManager_CustomThemeList:SetValue(nil)
		end)

		groupbox:AddButton('Set as default', function()
			if Options.ThemeManager_CustomThemeList.Value ~= nil and Options.ThemeManager_CustomThemeList.Value ~= '' then
				self:SaveDefault(Options.ThemeManager_CustomThemeList.Value)
				self.Library:Notify(string.format('Set default theme to %q', Options.ThemeManager_CustomThemeList.Value))
			end
		end)

		ThemeManager:LoadDefault()

		local function UpdateTheme()
			self:ThemeUpdate()
		end

		Options.BackgroundColor:OnChanged(UpdateTheme)
		Options.MainColor:OnChanged(UpdateTheme)
		Options.AccentColor:OnChanged(UpdateTheme)
		Options.SecondaryColor:OnChanged(UpdateTheme)
		Options.OutlineColor:OnChanged(UpdateTheme)
		Options.FontColor:OnChanged(UpdateTheme)
	end

	-- Theme names end up in file paths: drop path separators / illegal characters so "../x" can't escape the folder.
	local function SanitizeFileName(file)
		if type(file) ~= 'string' then
			return nil
		end

		file = file:gsub('[%c<>:"/\\|%?%*]', ''):gsub('^%s+', ''):gsub('%s+$', '')
		file = file:gsub('^%.+', '')

		return file ~= '' and file or nil
	end

	function ThemeManager:GetCustomTheme(file)
		file = SanitizeFileName(file)
		if not file then
			return nil
		end

		local path = self.Folder .. '/themes/' .. file
		if not isfile(path) then
			return nil
		end

		local data = readfile(path)
		local success, decoded = pcall(httpService.JSONDecode, httpService, data)

		if not success or type(decoded) ~= 'table' then
			return nil
		end

		return decoded
	end

	-- Returns true when the theme was written, so callers know whether to refresh their lists.
	function ThemeManager:SaveCustomTheme(file)
		local name = SanitizeFileName(file)

		if not name then
			self.Library:Notify('Invalid file name for theme (empty)', 3)
			return false
		end

		local theme = {}

		for _, field in next, THEME_FIELDS do
			theme[field] = Options[field].Value:ToHex()
		end

		local ok, err = pcall(writefile, self.Folder .. '/themes/' .. name .. '.json', httpService:JSONEncode(theme))

		if not ok then
			self.Library:Notify('Failed to save theme: ' .. tostring(err), 3)
			return false
		end

		self.Library:Notify(string.format('Saved theme %q', name), 2)
		return true
	end

	function ThemeManager:ReloadCustomThemes()
		local list = listfiles(self.Folder .. '/themes')

		local out = {}
		for i = 1, #list do
			-- file name (with extension) after the last / or \ separator
			local name = list[i]:match('([^/\\]+%.json)$')

			if name then
				table.insert(out, name)
			end
		end

		table.sort(out)

		return out
	end

	function ThemeManager:SetLibrary(lib)
		self.Library = lib
	end

	function ThemeManager:BuildFolderTree()
		local paths = {}

		-- build the entire tree if a path is like some-hub/phantom-forces
		-- makefolder builds the entire tree on Synapse X but not other exploits

		local parts = self.Folder:split('/')
		for idx = 1, #parts do
			paths[#paths + 1] = table.concat(parts, '/', 1, idx)
		end

		table.insert(paths, self.Folder .. '/themes')
		table.insert(paths, self.Folder .. '/settings')

		for i = 1, #paths do
			local str = paths[i]
			if not isfolder(str) then
				makefolder(str)
			end
		end
	end

	function ThemeManager:SetFolder(folder)
		self.Folder = folder
		self:BuildFolderTree()
	end

	function ThemeManager:CreateGroupBox(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		return tab:AddLeftGroupbox('Themes')
	end

	function ThemeManager:ApplyToTab(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		local groupbox = self:CreateGroupBox(tab)
		self:CreateThemeManager(groupbox)
	end

	function ThemeManager:ApplyToGroupbox(groupbox)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		self:CreateThemeManager(groupbox)
	end

	ThemeManager:BuildFolderTree()
end

return ThemeManager
