import 'package:git/git.dart';

Future<String?> getCurrentBranch(String? projectRootPath) async {
  if (projectRootPath == null) return null;

  return GitDir.isGitDir(projectRootPath)
      .then((isGitDir) async {
    if (isGitDir) {
      var git = await GitDir.fromExisting(projectRootPath);
      var branch = await git.currentBranch();
      return branch.branchName;
    }
    return null;
  });
}