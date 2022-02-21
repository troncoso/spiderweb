import 'package:github/github.dart';

class SpiderwebIssue {
  static fromIssue(Issue issue) {
    return SpiderwebIssue(
        number: issue.number,
        url: issue.htmlUrl,
        title: issue.title,
        labels: issue.labels,
        milestone: issue.milestone,
        createdAt: issue.createdAt,
    );
  }

  SpiderwebIssue({
    this.number = 0,
    this.url = '',
    this.title = '',
    List<IssueLabel>? labels,
    this.milestone,
    this.pullRequest,
    this.createdAt,
    this.currentIssue = false,
  }) {
    if (labels != null) {
      this.labels = labels;
    }
  }

  int number;
  String url;
  String title;
  List<IssueLabel> labels = <IssueLabel>[];
  Milestone? milestone;
  PullRequest? pullRequest;
  DateTime? createdAt;
  bool currentIssue;
}