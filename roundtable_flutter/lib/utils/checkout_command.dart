/// The shell one-liner that puts a local clone on [branch] with its latest
/// commits, so the dev can test a task's changes on their own machine.
/// `git checkout` creates the local tracking branch from `origin/<branch>`
/// on the first run; `git pull` catches up when it already exists.
String checkoutCommand(String branch) =>
    'git fetch && git checkout $branch && git pull';
