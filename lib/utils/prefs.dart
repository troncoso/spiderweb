import 'package:github/github.dart';
import 'package:shared_preferences/shared_preferences.dart';

const DOMAIN_MILESTONE = 'milestone';
const KEY_GITHUB_TOKEN = 'githubToken';

String prefKey(String domain, int id, String field) {
  return '$domain:$id:$field';
}

String milestonePrefKey(int milestoneId, String field) {
  return prefKey(DOMAIN_MILESTONE, milestoneId, field);
}

MilestonePrefs getMilestonePrefs(SharedPreferences prefs, Milestone milestone) {
  return MilestonePrefs(
      projectRootPath: prefs.getString(milestonePrefKey(milestone.id!, 'projectRootPath')),
      branchFrom: prefs.getString(milestonePrefKey(milestone.id!, 'branchFrom')),
      mergeTo: prefs.getString(milestonePrefKey(milestone.id!, 'mergeTo')),
  );
}

saveMilestonePrefs(SharedPreferences prefs, Milestone milestone, MilestonePrefs prefValues) async {
  var milestoneId = milestone.id!;
  await prefs.setString(milestonePrefKey(milestoneId, 'projectRootPath'), prefValues.projectRootPath ?? '');
  await prefs.setString(milestonePrefKey(milestoneId, 'branchFrom'), prefValues.branchFrom ?? '');
  await prefs.setString(milestonePrefKey(milestoneId, 'mergeTo'), prefValues.mergeTo ?? '');
}

class MilestonePrefs {
  MilestonePrefs({ this.projectRootPath, this.branchFrom, this.mergeTo });

  final String? projectRootPath;
  final String? branchFrom;
  final String? mergeTo;
}