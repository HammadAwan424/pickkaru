with open('lib/student/poll/student_poll_page.dart', 'r') as f:
    content = f.read()

# Add import for RideStatusBanner
content = content.replace(
    "import 'widgets/student_controls.dart';",
    "import 'widgets/student_controls.dart';\nimport 'widgets/components/ride_status_banner.dart';"
)

# Remove RideStatusBanner class from the file
start_idx = content.find("class RideStatusBanner extends StatelessWidget {")
if start_idx != -1:
    end_idx = content.find("class PeriodSwitcher extends StatelessWidget {")
    if end_idx != -1:
        content = content[:start_idx] + content[end_idx:]

with open('lib/student/poll/student_poll_page.dart', 'w') as f:
    f.write(content)

print("Removed RideStatusBanner from student_poll_page.dart.")
