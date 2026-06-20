with open('lib/student/poll/student_poll_page.dart', 'r') as f:
    content = f.read()

start_idx = content.find("class RideStatusBanner extends ConsumerWidget {")
if start_idx != -1:
    end_idx = content.find("class PeriodSwitcher extends StatelessWidget {")
    if end_idx != -1:
        content = content[:start_idx] + content[end_idx:]

with open('lib/student/poll/student_poll_page.dart', 'w') as f:
    f.write(content)

print("Removed remaining RideStatusBanner.")
