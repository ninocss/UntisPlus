import os
import re

settings_dir = r'C:\Users\nino\Documents\Projects\Untis+\lib\screens\settings'

# SwitchListTile replacement template with expressive styling
thumb_icon_code = '''
                        thumbIcon: WidgetStateProperty.resolveWith<Icon?>((Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Icon(Icons.check);
                          }
                          return const Icon(Icons.close);
                        }),
'''

for filename in os.listdir(settings_dir):
    if filename.endswith('.dart'):
        path = os.path.join(settings_dir, filename)
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # We find SwitchListTile.adaptive( and insert the thumbIcon right after it
        new_content = re.sub(
            r'SwitchListTile\.adaptive\(', 
            'SwitchListTile.adaptive(\n' + thumb_icon_code, 
            content
        )
        
        # Also let's change Card( to look more expressive (e.g. adding margin, different color)
        # Actually they are already Card(elevation: 0, color: cs.surfaceContainerHigh)
        
        if new_content != content:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f'Updated {filename}')
