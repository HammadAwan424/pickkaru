import os
import re

files = [
    'lib/student/poll/student_poll_page.dart',
    'lib/student/poll/widgets/student_controls.dart'
]

replacements = [
    ('_PollPeriodView', 'PollPeriodView'),
    ('_RideStatusBanner', 'RideStatusBanner'),
    ('_PeriodSwitcher', 'PeriodSwitcher'),
    ('_PollScaffold', 'PollScaffold'),
    ('_EmptyState', 'EmptyState'),
    ('_ErrorState', 'ErrorState'),
    ('_PublicStudent', 'PublicStudent'),
    ('_CustomChoiceButton', 'CustomChoiceButton')
]

for file in files:
    with open(file, 'r') as f:
        content = f.read()
    
    for old, new in replacements:
        content = content.replace(old, new)
        
    with open(file, 'w') as f:
        f.write(content)

print("Renamed widgets.")
