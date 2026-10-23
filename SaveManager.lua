local httpService = game:GetService('HttpService')

local SaveManager = {} do
	SaveManager.Folder = 'LinoriaLibSettings'
	SaveManager.Ignore = {}
	SaveManager.Parser = {
		Toggle = {
			Save = function(idx, object)
				return { type = 'Toggle', idx = idx, value = object.Value }
			end,
			Load = function(idx, data)
				if Toggles[idx] then
					Toggles[idx]:SetValue(data.value)
				end
			end,
		},
		Slider = {
			Save = function(idx, object)
				return { type = 'Slider', idx = idx, value = tostring(object.Value) }
			end,
			Load = function(idx, data)
				if Options[idx] then
					Options[idx]:SetValue(data.value)
				end
			end,
		},
		Dropdown = {
			Save = function(idx, object)
				-- `multi` was misspelled `mutli` before; Load never read it, so old configs stay compatible
				return { type = 'Dropdown', idx = idx, value = object.Value, multi = object.Multi }
			end,
			Load = function(idx, data)
				if Options[idx] then
					Options[idx]:SetValue(data.value)
				end
			end,
		},
		ColorPicker = {
			Save = function(idx, object)
				return { type = 'ColorPicker', idx = idx, value = object.Value:ToHex(), transparency = object.Transparency }
			end,
			Load = function(idx, data)
				if Options[idx] then
					Options[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency)
				end
			end,
		},
		KeyPicker = {
			Save = function(idx, object)
				return { type = 'KeyPicker', idx = idx, mode = object.Mode, key = object.Value }
			end,
			Load = function(idx, data)
				if Options[idx] then
					Options[idx]:SetValue({ data.key, data.mode })
				end
			end,
		},

		Input = {
			Save = function(idx, object)
				return { type = 'Input', idx = idx, text = object.Value }
			end,
			Load = function(idx, data)
				if Options[idx] and type(data.text) == 'string' then
					Options[idx]:SetValue(data.text)
				end
			end,
		},
	}

	-- Config names become file names: strip path separators and characters Windows refuses,
	-- so a name like "../../x" can never escape the settings folder.
	local function SanitizeName(name)
		if type(name) ~= 'string' then
			return nil
		end

		name = name:gsub('[%c<>:"/\\|%?%*]', ''):gsub('^%s+', ''):gsub('%s+$', '')
		name = name:gsub('^%.+', '') -- no hidden / relative names

		if name == '' then
			return nil
		end

		return name
	end

	SaveManager.SanitizeName = SanitizeName

	function SaveManager:SetIgnoreIndexes(list)
		for _, key in next, list do
			self.Ignore[key] = true
		end
	end

	function SaveManager:SetFolder(folder)
		self.Folder = folder;
		self:BuildFolderTree()
	end

	function SaveManager:Save(name)
		name = SanitizeName(name)

		if (not name) then
			return false, 'no config file is selected'
		end

		local fullPath = self.Folder .. '/settings/' .. name .. '.json'

		local data = {
			objects = {}
		}

		for idx, toggle in next, Toggles do
			if self.Ignore[idx] then continue end
			if not self.Parser[toggle.Type] then continue end

			table.insert(data.objects, self.Parser[toggle.Type].Save(idx, toggle))
		end

		for idx, option in next, Options do
			if not self.Parser[option.Type] then continue end
			if self.Ignore[idx] then continue end

			table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
		end

		local success, encoded = pcall(httpService.JSONEncode, httpService, data)
		if not success then
			return false, 'failed to encode data'
		end

		local written, err = pcall(writefile, fullPath, encoded)
		if not written then
			return false, 'failed to write file: ' .. tostring(err)
		end

		return true
	end

	function SaveManager:Load(name)
		name = SanitizeName(name)

		if (not name) then
			return false, 'no config file is selected'
		end

		local file = self.Folder .. '/settings/' .. name .. '.json'
		if not isfile(file) then return false, 'invalid file' end

		local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
		if not success or type(decoded) ~= 'table' or type(decoded.objects) ~= 'table' then
			return false, 'decode error'
		end

		for _, option in next, decoded.objects do
			local parser = type(option) == 'table' and self.Parser[option.type]

			if parser then
				-- task.spawn() so the config loading wont get stuck.
				-- pcall so a single broken entry (renamed option, bad colour...) doesn't abort the callback silently.
				task.spawn(function()
					local ok, err = pcall(parser.Load, option.idx, option)

					if not ok then
						warn(string.format('[SaveManager] could not load %q: %s', tostring(option.idx), tostring(err)))
					end
				end)
			end
		end

		return true
	end

	function SaveManager:Delete(name)
		name = SanitizeName(name)

		if (not name) then
			return false, 'no config file is selected'
		end

		local file = self.Folder .. '/settings/' .. name .. '.json'
		if not isfile(file) then return false, 'invalid file' end

		local ok, err = pcall(delfile, file)
		if not ok then
			return false, 'failed to delete file: ' .. tostring(err)
		end

		-- don't leave autoload pointing at a config that no longer exists
		local autoload = self.Folder .. '/settings/autoload.txt'
		if isfile(autoload) and readfile(autoload) == name then
			pcall(delfile, autoload)
		end

		return true
	end

	function SaveManager:IgnoreThemeSettings()
		self:SetIgnoreIndexes({
			"BackgroundColor", "MainColor", "AccentColor", "SecondaryColor", "OutlineColor", "FontColor", -- themes
			"ThemeManager_ThemeList", 'ThemeManager_CustomThemeList', 'ThemeManager_CustomThemeName', -- themes
		})
	end

	function SaveManager:BuildFolderTree()
		local paths = {}

		-- makefolder only creates one level on most executors, so build "hub/game" one part at a time
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

	function SaveManager:RefreshConfigList()
		local list = listfiles(self.Folder .. '/settings')

		local out = {}
		for i = 1, #list do
			-- last path component of "<folder>/settings/<name>.json", for both / and \ separators
			local name = list[i]:match('([^/\\]+)%.json$')

			if name then
				table.insert(out, name)
			end
		end

		table.sort(out)

		return out
	end

	function SaveManager:SetLibrary(library)
		self.Library = library
	end

	function SaveManager:LoadAutoloadConfig()
		if isfile(self.Folder .. '/settings/autoload.txt') then
			local name = readfile(self.Folder .. '/settings/autoload.txt')

			local success, err = self:Load(name)
			if not success then
				return self.Library:Notify('Failed to load autoload config: ' .. err)
			end

			self.Library:Notify(string.format('Auto loaded config %q', name))
		end
	end


	function SaveManager:BuildConfigSection(tab)
		assert(self.Library, 'Must set SaveManager.Library')

		local section = tab:AddRightGroupbox('Configuration')

		section:AddInput('SaveManager_ConfigName',    { Text = 'Config name' })
		section:AddDropdown('SaveManager_ConfigList', { Text = 'Config list', Values = self:RefreshConfigList(), AllowNull = true })

		section:AddDivider()

		local function RefreshList()
			Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
			Options.SaveManager_ConfigList:SetValue(nil)
		end

		section:AddButton('Create config', function()
			local name = SanitizeName(Options.SaveManager_ConfigName.Value)

			if not name then
				return self.Library:Notify('Invalid config name (empty)', 2)
			end

			local success, err = self:Save(name)
			if not success then
				return self.Library:Notify('Failed to save config: ' .. err)
			end

			self.Library:Notify(string.format('Created config %q', name))

			RefreshList()
		end):AddButton('Load config', function()
			local name = Options.SaveManager_ConfigList.Value

			local success, err = self:Load(name)
			if not success then
				return self.Library:Notify('Failed to load config: ' .. err)
			end

			self.Library:Notify(string.format('Loaded config %q', name))
		end)

		section:AddButton('Overwrite config', function()
			local name = Options.SaveManager_ConfigList.Value

			local success, err = self:Save(name)
			if not success then
				return self.Library:Notify('Failed to overwrite config: ' .. err)
			end

			self.Library:Notify(string.format('Overwrote config %q', name))
		end)

		-- double click so a stray click can't wipe a config
		section:AddButton({
			Text = 'Delete config',
			DoubleClick = true,
			Func = function()
				local name = Options.SaveManager_ConfigList.Value

				local success, err = self:Delete(name)
				if not success then
					return self.Library:Notify('Failed to delete config: ' .. err)
				end

				self.Library:Notify(string.format('Deleted config %q', name))

				RefreshList()

				if not isfile(self.Folder .. '/settings/autoload.txt') then
					SaveManager.AutoloadLabel:SetText('Current autoload config: none')
				end
			end,
		})

		section:AddButton('Refresh list', RefreshList)

		section:AddButton('Set as autoload', function()
			local name = SanitizeName(Options.SaveManager_ConfigList.Value)

			-- writefile(path, nil) used to throw when nothing was selected
			if not name then
				return self.Library:Notify('Select a config first', 2)
			end

			writefile(self.Folder .. '/settings/autoload.txt', name)
			SaveManager.AutoloadLabel:SetText('Current autoload config: ' .. name)
			self.Library:Notify(string.format('Set %q to auto load', name))
		end)

		SaveManager.AutoloadLabel = section:AddLabel('Current autoload config: none', true)

		if isfile(self.Folder .. '/settings/autoload.txt') then
			local name = readfile(self.Folder .. '/settings/autoload.txt')
			SaveManager.AutoloadLabel:SetText('Current autoload config: ' .. name)
		end

		SaveManager:SetIgnoreIndexes({ 'SaveManager_ConfigList', 'SaveManager_ConfigName' })
	end

	SaveManager:BuildFolderTree()
end

return SaveManager
