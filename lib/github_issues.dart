import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:github/github.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:spiderweb/utils/branch_names.dart';
import 'package:spiderweb/widgets/dialogs.dart';
import 'package:spiderweb/widgets/hex_color.dart';
import 'package:collection/collection.dart';
import 'package:spiderweb/utils/git.dart';
import 'package:spiderweb/utils/github.dart';
import 'package:spiderweb/utils/prefs.dart';
import 'package:spiderweb/models/spiderweb_issue.dart';
import 'package:spiderweb/widgets/margins.dart';
import 'package:spiderweb/widgets/snapshot_status.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:git/git.dart';
import 'widgets/github_tag.dart';

class GithubIssues extends StatefulWidget {
  const GithubIssues({Key? key}) : super(key: key);

  @override
  _GithubIssuesState createState() => _GithubIssuesState();
}

class _GithubIssuesState extends State<GithubIssues> {
  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(minutes: 3), (timer) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Github Issues'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
            child: FutureBuilder<SharedPreferences>(
                future: SharedPreferences.getInstance(),
                builder: (context, snapshot) {
                  var futureStatus = buildFutureStatus(snapshot,
                      loadingText: 'Loading Configuration...',
                      errorPrefix: 'Error loading configuration',
                      noDataText: 'Could not load configuration');

                  if (futureStatus != null) return futureStatus;

                  var prefs = snapshot.data!;

                  return Column(
                      // mainAxisSize: MainAxisSize.min,
                      children: [
                        buildHeaderButtons(context, prefs),
                        const VerticalMargin(),
                        buildIssueList(context, prefs)
                      ]);
                }
            )
        )
      )
    );
  }

  /// The button bar at the top of the screen
  Widget buildHeaderButtons(BuildContext context, SharedPreferences prefs) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          DialogButton('Set GitHub Token', () async {
            await showSingleInputDialog(context, 'GitHub Token', (value) async {
              await prefs.setString(KEY_GITHUB_TOKEN, value);
              Navigator.pop(context);
              setState(() {});
            }, startingValue: prefs.getString(KEY_GITHUB_TOKEN));
          },),
          const HorizontalMargin(),
          DialogButton('Refresh', () { setState(() {}); })
        ]
    );
  }

  /// The list of milestones and their respective issues
  Widget buildIssueList(BuildContext context, SharedPreferences prefs) {
    return FutureBuilder<List<SpiderwebIssue>>(
      future: getIssues(),
      builder: (context, snapshot) {
        var futureStatus = buildFutureStatus(snapshot,
            noDataText: 'No issues found. You either don\'t have any, or your GitHub token hasn\'t been set or is invalid'
        );
        if (futureStatus != null) return futureStatus;

        var issuesByMilestone = getIssuesByMilestone(snapshot.data!);
        var issueLists = issuesByMilestone.entries
            .map((entry) => GithubIssuesList(entry.key, entry.value, prefs))
            .toList();
        return Column(children: issueLists);
      }
    );
  }
}

class GithubIssuesList extends StatefulWidget {
  const GithubIssuesList(this.milestone, this.issues, this.prefs, {Key? key}) : super(key: key);

  final Milestone milestone;
  final List<SpiderwebIssue> issues;
  final SharedPreferences prefs;

  @override
  _GithubIssuesListState createState() => _GithubIssuesListState();
}

class _GithubIssuesListState extends State<GithubIssuesList> {

  MilestonePrefs milestonePrefs = MilestonePrefs();
  bool prWillFixIssue = false;

  @override
  void initState() {
    super.initState();
    milestonePrefs = getMilestonePrefs(widget.prefs, widget.milestone);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: getCurrentBranch(milestonePrefs.projectRootPath),
      builder: (context, snapshot) {

        var currentIssueWidget = buildCurrentIssue(snapshot);
        SpiderwebIssue? currentIssue;
        if (currentIssueWidget is GithubIssue) {
          currentIssue = currentIssueWidget.issue;
        } else {
          currentIssueWidget = Container(alignment: Alignment.centerLeft, child: currentIssueWidget);
        }
        var issueList = widget.issues
          .where((issue) => currentIssue == null || issue.number != currentIssue.number)
          .map((issue) => GithubIssue(issue, () { onInactiveIssuePressed(issue, currentIssue != null); }))
          .toList();

        return Column(
          children: [
            buildHeader(),
            currentIssueWidget,
            const Divider(color: Colors.black45),
            Column(children: issueList)
          ]
        );
      }
    );
  }

  isConfigured() {
    return (milestonePrefs.projectRootPath?.isNotEmpty ?? false)
        && (milestonePrefs.branchFrom?.isNotEmpty ?? false)
        && (milestonePrefs.mergeTo?.isNotEmpty ?? false);
  }

  Widget buildHeader() {
    var title = Text(widget.milestone.title!,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
    var configureButton = MaterialButton(
      child: const Text('Configure Milestone',
        style: TextStyle(color: Colors.blue),
      ),
      onPressed: () => showConfiguration(widget.prefs),
    );

    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
              children: [
                title,
                buildStatusIcon(),
              ]
          ),
          configureButton,
        ]
    );
  }

  Widget buildStatusIcon() {
    var configured = isConfigured();
    var configuredMsg = configured ? 'Linked to project at ${milestonePrefs.projectRootPath}' : 'Milestone not configured';
    var configuredIcon = configured ? Icons.check : Icons.close;
    var configuredColor = configured ? Colors.green : Colors.red;

    return Tooltip(
        message: configuredMsg,
        child: Icon(configuredIcon, color: configuredColor),
    );
  }

  Widget buildCurrentIssue(AsyncSnapshot<String?> snapshot) {
    var futureStatus = buildFutureStatus(snapshot, noDataText: 'No current issue' );
    if (futureStatus != null) return futureStatus;

    var branch = snapshot.data!;
    if (branch == milestonePrefs.branchFrom || branch == milestonePrefs.mergeTo) return const Text('No current issue');

    var issueNumber = getIssueNumberFromBranchName(branch);
    if (issueNumber == null) return Text('Could not determine current issue from branch $branch');

    var issue = widget.issues.firstWhereOrNull((issue) => issue.number == issueNumber);
    if (issue == null) return Text('Could not find current issue based on branch $branch');

    return GithubIssue(issue, () { onActiveIssuePressed(issue); }, bgColor: Colors.lightBlueAccent,);
  }

  showConfiguration(SharedPreferences prefs) async {
    await showDialog(context: context, builder: (context) {
      return MilestoneConfigDialog(widget.milestone, prefs, () {
        setState(() {
          milestonePrefs = getMilestonePrefs(prefs, widget.milestone);
        });
      });
    });
  }

  onInactiveIssuePressed(SpiderwebIssue issue, bool differentIssueActive) async {
    refreshAndClose (context) {
      setState(() {});
      Navigator.pop(context);
    }
    await showDialog(context: context, builder: (context) {
      var loadingNotifier = ValueNotifier(false);
      return ValueListenableBuilder(
          valueListenable: loadingNotifier,
          builder: (context, bool loading, _) {
            return SimpleDialog(
                title: Text(issue.title),
                children: [
                  IssueDialogOption('Open in Browser', loading ? null : () async {
                    await launch(issue.url);
                    Navigator.pop(context);
                  }),
                  IssueDialogOption('Create Branch', loading ? null : () async {
                    if (differentIssueActive) {
                      await showDialog(context: context, builder: (context) {
                        return SimpleDialog(
                          contentPadding: EdgeInsets.all(16),
                          children: [
                            const Text('Another issue is currently active. Stash or discard that one before starting a new one.'),
                            const VerticalMargin(),
                            ElevatedButton(child: const Text('Close'), onPressed: () {
                              Navigator.pop(context);
                            },)
                          ],
                        );
                      });
                      return;
                    }
                    loadingNotifier.value = true;
                    var git = await GitDir.fromExisting(milestonePrefs.projectRootPath!);
                    var issueBranchName = convertIssueToBranch(issue);
                    var branches = await git.branches();
                    var existingBranch = branches.firstWhereOrNull((branch) => branch.branchName == issueBranchName);

                    if (existingBranch == null) {
                      // Create new branch and check it out
                      await git.runCommand([ 'fetch', 'origin']);
                      await git.runCommand([ 'pull' ]);
                      await git.runCommand([ 'checkout', '-b', issueBranchName, 'origin/${milestonePrefs.branchFrom}']);
                    } else {
                      await git.runCommand([ 'checkout', issueBranchName ]);
                    }

                    // Apply stash if it exists
                    await applyStash(git, issue);

                    loadingNotifier.value = false;
                    refreshAndClose(context);
                  }, hasConfig: isConfigured(),),
                  IssueDialogOption('Cancel', loading ? null : () {
                    Navigator.pop(context);
                  }),
                ]
            );
          });
    });
  }

  onActiveIssuePressed(SpiderwebIssue issue) async {
    refreshAndClose (context) {
      setState(() {});
      Navigator.pop(context);
    }
    await showDialog(context: context, builder: (context) {
      var loadingNotifier = ValueNotifier(false);
      return ValueListenableBuilder(
        valueListenable: loadingNotifier,
        builder: (context, bool loading, _) {
          return SimpleDialog(
              title: Text(issue.title),
              children: [
                IssueDialogOption('Open in Browser', loading ? null : () async {
                  await launch(issue.url);
                  Navigator.pop(context);
                }),
                IssueDialogOption('Create Pull Request', loading ? null : () async {
                  await showDialog(context: context, builder: (context) {
                    return SimpleDialog(
                        children: [
                          StatefulBuilder(
                              builder: (context, setState) {
                                var commitMsg = convertIssueToCommitMessage(issue, prWillFixIssue);
                                var branchName = convertIssueToBranch(issue);
                                return Column(
                                    children: [
                                      Column(
                                          children: [
                                            const Text('This PR will fix this issue'),
                                            Checkbox(value: prWillFixIssue, onChanged: (bool? value) => setState(() { prWillFixIssue = value!; }))
                                          ]
                                      ),
                                      ElevatedButton( child: Text('Commit and create PR'),
                                        onPressed: () async {
                                          var git = await GitDir.fromExisting(milestonePrefs.projectRootPath!);
                                          await git.runCommand([ 'add', '-A' ]);
                                          await git.runCommand([ 'commit', '-m', '"$commitMsg"' ]);
                                          await git.runCommand([ 'push', '-u', 'origin', 'HEAD' ]);

                                          var github = GitHub(auth: Authentication.withToken(widget.prefs.getString(KEY_GITHUB_TOKEN)));
                                          await github.pullRequests.create(SCOREBOARD_REPO_SLUG, CreatePullRequest(commitMsg,
                                              branchName,
                                              milestonePrefs.mergeTo,
                                              body: convertIssueToPrBody(issue, prWillFixIssue))
                                          );
                                          await git.runCommand([ 'checkout', milestonePrefs.branchFrom! ]);
                                          Navigator.pop(context);
                                        },)
                                    ]
                                );
                              }
                          )
                        ]
                    );
                  });
                  refreshAndClose(context);
                }, hasConfig: isConfigured(),),
                IssueDialogOption('Stash and Reset', loading ? null : () async {
                  var git = await GitDir.fromExisting(milestonePrefs.projectRootPath!);
                  try {
                    await git.runCommand([ 'stash', 'push', '-m', '$GIT_STASH_PREFIX-${issue.number}' ]);
                  } catch (error) {
                    print('Failed to stash changes. This likely means there weren\'t any');
                  }
                  await git.runCommand([ 'checkout', milestonePrefs.branchFrom! ]);
                  refreshAndClose(context);
                }, hasConfig: isConfigured(),),
                IssueDialogOption('Discard and Reset', loading ? null : () async {
                  var git = await GitDir.fromExisting(milestonePrefs.projectRootPath!);
                  await git.runCommand([ 'reset', '--hard' ]);
                  await git.runCommand([ 'clean', '-f', '-d' ]);
                  await git.runCommand([ 'checkout', milestonePrefs.branchFrom! ]);
                  refreshAndClose(context);
                }, hasConfig: isConfigured(),),
                IssueDialogOption('Cancel', loading ? null : () {
                  Navigator.pop(context);
                }),
              ]
          );
        });
    });
  }
}

class IssueDialogOption extends SimpleDialogOption {
  IssueDialogOption(this.label, onPressed, { Key? key, bool hasConfig = true }) : super(key: key,
    padding: const EdgeInsets.all(16),
    child: Text(label),
    onPressed: hasConfig ? onPressed : null
  );

  final String label;
}

class MilestoneConfigDialog extends StatefulWidget {
  const MilestoneConfigDialog(this.milestone, this.prefs, this.onSave, {Key? key}) : super(key: key);

  final Milestone milestone;
  final SharedPreferences prefs;
  final Function onSave;

  @override
  _MilestoneConfigDialogState createState() => _MilestoneConfigDialogState();
}

class _MilestoneConfigDialogState extends State<MilestoneConfigDialog> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    var prefs = widget.prefs;
    var milestoneId = widget.milestone.id!;
    var projectRootController = TextEditingController(text: prefs.getString(milestonePrefKey(milestoneId, 'projectRootPath')));
    var branchFromController = TextEditingController(text: prefs.getString(milestonePrefKey(milestoneId, 'branchFrom')));
    var mergeToController = TextEditingController(text: prefs.getString(milestonePrefKey(milestoneId, 'mergeTo')));
    var github = GitHub(auth: Authentication.withToken(widget.prefs.getString(KEY_GITHUB_TOKEN)));
    return SimpleDialog(
      children: [Container(
        padding: EdgeInsets.all(16),
        child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          margin: EdgeInsets.only(bottom: 16),
                          child: Text('Configure ${widget.milestone.title}', style: TextStyle(fontSize: 18))
                      ),
                      Row(
                          children: [
                            Expanded(child: TextFormField(
                              controller: projectRootController,
                              decoration: InputDecoration(labelText: 'Project root path'),
                            ),),
                            MaterialButton(child: Text('Browse files'), onPressed: () => selectDir(projectRootController),)
                          ]
                      ),
                      BranchSelector('Branch From', branchFromController, github),
                      BranchSelector('Merge To', mergeToController, github),
                    ]
                ),
                Container(
                  margin: EdgeInsets.only(top: 16),
                  child: ElevatedButton(onPressed: () { save(prefs, projectRootController, branchFromController, mergeToController, context); }, child: Text('Save'))
                )
              ],
            )
        ),
      ),]
    );
  }

  save(SharedPreferences prefs, projectRootPathController, branchFromController, mergeToController, context) async {
    await saveMilestonePrefs(prefs, widget.milestone, MilestonePrefs(
      projectRootPath: projectRootPathController.text,
      branchFrom: branchFromController.text,
      mergeTo: mergeToController.text,
    ));

    Navigator.pop(context);
    widget.onSave();
  }

  selectDir(TextEditingController controller) async {
    var dir = await FilePicker.platform.getDirectoryPath();
    if (dir != null) {
      // This part is unnecessary
      dir = dir.replaceAll('/Volumes/Macintosh HD', '');
      controller.text = dir;
    }
  }
}

class BranchSelector extends TypeAheadField<Branch> {
  BranchSelector(this.label, this.controller, this.github, {Key? key}) : super(key: key,
      itemBuilder: (context, Branch suggestion) {
        return ListTile(title: Text(suggestion.name!));
      },
      onSuggestionSelected: (suggestion) {
        controller.text = suggestion.name!;
      },
      suggestionsCallback: (pattern) async {
        var branches = github.repositories.listBranches(SCOREBOARD_REPO_SLUG);
        List<Branch> branchList = [];
        await for (final branch in branches) {
          if (branch.name!.startsWith(pattern)) {
            branchList.add(branch);
          }
        }
        return branchList;
      },
      textFieldConfiguration: TextFieldConfiguration(
        controller: controller,
        decoration: InputDecoration(labelText: label)
      ));

  final String label;
  final TextEditingController controller;
  final GitHub github;
}


class GithubIssue extends StatelessWidget {
  const GithubIssue(this.issue, this.onPressed, {Key? key, this.bgColor = Colors.white}) : super(key: key);

  final SpiderwebIssue issue;
  final Color bgColor;
  final GestureTapCallback onPressed;

  @override
  Widget build(BuildContext context) {
    List<Container> tags = [];
    for (final label in issue.labels) {
      if (VALID_TAGS.contains(label.name)) {
        tags.add(Container(
            margin: const EdgeInsets.only(left: 8),
            child: GithubTag(label.name, HexColor(label.color))
        ));
      }
    }
    return InkWell(
      onTap: onPressed,
      child: Card(
        color: bgColor,
        child: IssueContent(issue, tags)
    ),);
  }
}

class IssueContent extends StatelessWidget {
  const IssueContent(this.issue, this.tags, {Key? key}) : super(key: key);

  final SpiderwebIssue issue;
  final List<Container> tags;

  @override
  Widget build(BuildContext context) {
    List<Widget> title = [
      Expanded(
        child: Text('#${issue.number} ${issue.title}'),
      )
    ];

    if (issue.pullRequest != null) {
      title.insert(0, const HorizontalMargin(size: 8,));
      title.insert(0, Tooltip(
        message: 'This issue has an open pull request. Click this icon to open it in a browser',
        child: InkWell(
          child: const Icon(Icons.merge_type),
          onTap: () async {
            await launch(issue.pullRequest!.htmlUrl!);
          },),
      ));
    }
    return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.centerLeft,
        child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                  children: title
              ),
              const VerticalMargin(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: tags,
              )
        ])
    );
  }
}


