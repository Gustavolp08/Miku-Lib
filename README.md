<img width="991" height="849" alt="image" src="https://github.com/user-attachments/assets/0dddf549-a763-4138-bb9b-674fce77a92a" />

<img width="480" height="266" alt="LetsGoApplauseGIFbyEmmys" src="https://github.com/user-attachments/assets/fb53448b-2f20-440f-ba11-d11f9a52313e" />

# Miku-Lib

UI library para Roblox com tema da Hatsune Miku (teal + rosa), baseada na LinoriaLib.

## Uso

```lua
local repo = 'https://raw.githubusercontent.com/Gustavolp08/Miku-Lib/main/'

local Library      = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'ThemeManager.lua'))()
local SaveManager  = loadstring(game:HttpGet(repo .. 'SaveManager.lua'))()

local Window = Library:CreateWindow({ Title = 'Miku Menu', Center = true, AutoShow = true })
local Tab = Window:AddTab('Main')
local Box = Tab:AddLeftGroupbox('Groupbox')

Box:AddToggle('MyToggle', { Text = 'Toggle', Default = true })
```

O `Example.lua` mostra todos os elementos (toggle, slider, dropdown, color picker, keybind, tabbox, dependency box, configs e temas).

## Novidades desta versão

**Correções**
- `Example.lua` apontava para uma URL inválida (`.../Library.lua/`) e para uma pasta `addons/` que não existe; agora carrega os arquivos da raiz.
- `Library:CreateWindow()` sem argumentos lançava erro.
- Conexões de `InputService` (dropdown) e `Players` (lista de jogadores) não eram desconectadas no `Unload`.
- `PlayerRemoving` disparava antes do jogador sair da lista, então o dropdown de players mantinha o jogador que saiu.
- `Library:OnUnload` sobrescrevia a própria função; agora aceita vários callbacks e um callback com erro não impede os outros.
- Reexecutar o script empilhava um segundo menu; a instância antiga é descarregada antes (`getgenv().MikuLibKeepOldInstance = true` desativa).
- Janela com `Size` customizado ignorava a altura nova nas abas; agora o conteúdo acompanha o tamanho.
- KeyPicker: tecla inválida de config antiga lançava erro todo frame; clique duplo abria dois listeners; entradas sem nome de tecla (gamepad/toque) quebravam; binds disparavam enquanto você digitava em um TextBox.
- Slider: `SetValue` (configs/scripts) agora respeita `Rounding`; `Min == Max` não gera mais NaN.
- Dropdown: seleção múltipla longa não vaza mais da caixa; lista de itens deixou de ser redesenhada a cada item.
- `BindableEvent` do botão de clique duplo vazava uma instância por clique.
- `Notify`/`SafeCallback` não quebram mais com valores que não são string.
- Menu não abre/fecha mais ao digitar a tecla do menu em um TextBox.
- Sem a API `Drawing` o cursor customizado é ignorado em vez de dar erro.
- Remoção do registry de cores passou de O(n) para O(1) (reconstruir dropdowns grandes ficava quadrático).

**SaveManager**
- Nomes de config são sanitizados (`../../x` não sai mais da pasta de settings).
- Typo `mutli` corrigido para `multi` ao salvar dropdowns.
- Entradas quebradas na config são ignoradas com `warn` em vez de falhar em silêncio.
- "Set as autoload" sem seleção não lança mais erro.
- Novo botão **Delete config** (com clique duplo) e `SaveManager:Delete(name)`.
- Lista de configs ordenada e lida corretamente com `/` e `\`.

**ThemeManager**
- Só as 6 chaves de cor são lidas de um tema customizado (antes qualquer chave do JSON era escrita dentro da `Library`).
- Trocar de tema atualiza o registry uma vez, em vez de seis.
- Nomes de tema sanitizados, "Load theme" sem seleção avisa, e salvar um tema mostra uma notificação.

**Recursos novos**
- `Library:CreateWindow` usa `gethui()` quando o executor oferece.
- `Dependency box` agora também aceita dropdown de seleção única (`{ Options.Mode, 'Advanced' }`).
- `Button:SetText(text)`.
- `Escape` no KeyPicker remove a tecla.

## Créditos

Base: [LinoriaLib](https://github.com/violin-suzutsuki/LinoriaLib).
