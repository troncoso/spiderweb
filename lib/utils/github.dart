import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:git/git.dart';
import 'package:github/github.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiderweb/models/spiderweb_issue.dart';
import 'package:spiderweb/utils/prefs.dart';
import 'package:spiderweb/widgets/github_tag.dart';

final SCOREBOARD_REPO_SLUG = RepositorySlug('SpiderStrategies', 'Scoreboard');
const GIT_STASH_PREFIX = 'spiderweb-automated-stash';

populateLatestPRs(GitHub github, List<SpiderwebIssue> issues) async {
  var pulls = await github.pullRequests.list(SCOREBOARD_REPO_SLUG).toList();
  // Sort by first pulling all open PRs to the top, then by creation date
  pulls.sort((pull1, pull2) {
    if (pull1.state == 'closed' && pull2.state != 'closed') return -1;
    if (pull2.state == 'closed' && pull1.state != 'closed') return 1;
    if (pull1.createdAt!.isAfter(pull2.createdAt!)) return -1;
    if (pull2.createdAt!.isAfter(pull1.createdAt!)) return 1;
    return pull1.title!.compareTo(pull2.title!);
  });

  for (final issue in issues) {
    var pull = pulls.firstWhereOrNull((pull) {
      return pull.title!.contains(issue.number.toString())
          || (pull.body == null ? false : pull.body!.contains(issue.number.toString()));
    });
    issue.pullRequest = pull;
  }
}

Future<List<SpiderwebIssue>> getIssues() async {
  return Future<List<SpiderwebIssue>>(() async {
    var prefs = await SharedPreferences.getInstance();
    var token = prefs.getString(KEY_GITHUB_TOKEN);
    if (token == null) return [];

    try {
      var github = GitHub(auth: Authentication.withToken(token));

      List<SpiderwebIssue> issues = [];
      await for (final issue in github.issues.listAll()) {
        issues.add(SpiderwebIssue.fromIssue(issue,));
      }

      await populateLatestPRs(github, issues);
      return issues;
    } catch (error) {
      return [];
    }
  });
}

int getIssuePriority(SpiderwebIssue issue) {
  var labels = issue.labels.map((l) => l.name);

  var priority = 100;
  for (final label in labels) {
    var index = TAG_PRIORITIES.indexOf(label);
    if (index >= 0 && index < priority) {
      priority = index + 1;
    }
  }

  // We can't work on blocked issues, so push them to the bottom of the list
  if (labels.contains('blocked')) {
    priority += 100;
  }
  return priority;
}

Map<Milestone, List<SpiderwebIssue>> getIssuesByMilestone(List<SpiderwebIssue> issues) {
  // Sort issues by priority first, then name
  issues.sort((issue1, issue2) {
    var issue1Priority = getIssuePriority(issue1);
    var issue2Priority = getIssuePriority(issue2);
    if (issue1Priority != issue2Priority) {
      return issue1Priority.compareTo(issue2Priority);
    }
    return issue1.createdAt!.compareTo(issue2.createdAt!);
  });

  // Use SplayTreeMap to order map by key
  var issuesByMilestone = SplayTreeMap<Milestone, List<SpiderwebIssue>>((key1, key2) {
    var firstDueDate = key1.dueOn;
    var secondDueDate = key2.dueOn;
    if (firstDueDate == null && secondDueDate != null) return -1;
    if (firstDueDate != null && secondDueDate == null) return 1;
    return firstDueDate!.compareTo(secondDueDate!);
  });

  var defaultMilestone = Milestone(id: 0, title: 'No Milestone');
  for (var issue in issues) {
    var milestone = issue.milestone ?? defaultMilestone;
    issuesByMilestone.putIfAbsent(milestone, () => []);
    issuesByMilestone[milestone]!.add(issue);
  }

  return issuesByMilestone;
}

/// Apply a stash to a given branch if one exists
applyStash(GitDir git, SpiderwebIssue issue) async {
  var results = await git.runCommand([ 'stash', 'list' ]);
  if (results.stdout != null && results.stdout.toString().trim().isNotEmpty) {
    var pattern = RegExp('stash@\\{(\\d+)\\}:.*$GIT_STASH_PREFIX-(\\d+)');
    var lines = results.stdout.toString();
    var lineList = lines.split('\n');
    var indexes = lineList.map((line) {
      if (line.trim().isEmpty) return null;

      var match = pattern.firstMatch(line);
      if (match == null || match.groupCount < 2) return null;

      return { 'index': match.group(1), 'number': match.group(2) };
    }).toList();
    var index = indexes.firstWhereOrNull((index) {
      return index != null && index['number'] == issue.number.toString();
    });

    if (index != null) {
      await git.runCommand([ 'stash', 'pop', index['index']! ]);
    }
  }
}