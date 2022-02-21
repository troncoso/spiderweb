import 'package:spiderweb/models/spiderweb_issue.dart';

class IssueNumberAndDescription {
  const IssueNumberAndDescription(this.issueNumber, this.description);

  final String issueNumber;
  final String description;
}

String convertIssueToBranch(SpiderwebIssue issue) {
  var issueNumber = issue.number;
  var description = issue.title;
  // Replace all non-alphanumeric (and underscores) with a space
  var cleanDescription = description.replaceAll(RegExp(r'[^0-9a-zA-Z _]'), ' ');
  // Convert any instance of multiple spaces to a single space
  cleanDescription = cleanDescription.replaceAll(RegExp(r'[ ]+'), ' ');
  // Lower case everything
  cleanDescription = cleanDescription.toLowerCase().trim();
  return 'issue-$issueNumber-${cleanDescription.split(' ').join('-')}';
}

String convertIssueToCommitMessage(SpiderwebIssue issue, bool isFix) {
  var issueNumber = issue.number;
  var description = issue.title;
  return '${isFix ? 'Fixes ' : ''}#$issueNumber $description';
}

String convertIssueToPrBody(SpiderwebIssue issue, bool isFix) {
  var issueNumber = issue.number;
  var description = issue.title;
  return '${isFix ? 'Fixes ' : ''}#$issueNumber';
}

int? getIssueNumberFromBranchName(String branch) {
  var firstMatch = RegExp(r'.*issue-(\d+)-[\w-]+').firstMatch(branch);

  var issueNumber = firstMatch?.group(1);
  return issueNumber == null ? null : int.parse(issueNumber);
}