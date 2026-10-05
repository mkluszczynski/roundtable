import 'non_terminal_task_statuses.dart';
import '../generated/protocol.dart';
import '../github_repo_client.dart';
import '../project_tools.dart';
import 'package:serverpod/serverpod.dart';

/// Basic CRUD for [Project]. Deletion is blocked while it has non-terminal
/// tasks, mirroring [AgentEndpoint]/[MachineEndpoint]'s guard.
class ProjectEndpoint extends Endpoint {
  Future<Project> create(
    Session session,
    String name,
    String repoUrl, {
    String? repoAccessToken,
    String? dockerImage,
    List<ProjectTool>? tools,
  }) async {
    return Project.db.insertRow(
      session,
      Project(
        name: name,
        repoUrl: repoUrl,
        repoAccessToken: repoAccessToken,
        repoAccessTokenUpdatedAt: repoAccessToken == null
            ? null
            : DateTime.now(),
        dockerImage: dockerImage,
        tools: validateProjectTools(tools ?? const []),
      ),
    );
  }

  Future<Project?> get(Session session, int id) async {
    return Project.db.findById(session, id);
  }

  Future<List<Project>> list(Session session) async {
    return Project.db.find(session);
  }

  /// Edits a project's name, repo URL and docker image. The access token
  /// goes through [updateRepoAccessToken], task defaults through
  /// `SettingsEndpoint.updateProjectTaskDefaults`.
  Future<Project> update(Session session, Project project) async {
    if (await Project.db.findById(session, project.id!) == null) {
      throw NotFoundException(message: 'Project ${project.id} not found');
    }
    return Project.db.updateRow(
      session,
      project,
      columns: (t) => [
        t.name,
        t.repoUrl,
        t.dockerImage,
      ],
    );
  }

  /// Replaces the toolchains the runner installs before each task.
  Future<Project> updateTools(
    Session session,
    int projectId,
    List<ProjectTool> tools,
  ) async {
    final project = await Project.db.findById(session, projectId);
    if (project == null) {
      throw NotFoundException(message: 'Project $projectId not found');
    }
    return Project.db.updateRow(
      session,
      project.copyWith(tools: validateProjectTools(tools)),
      columns: (t) => [t.tools],
    );
  }

  /// Suggests the toolchains of the GitHub repo at [repoUrl] from its
  /// manifests (pubspec.yaml, package.json, .nvmrc, …) — a proposal the
  /// panel shows for confirmation. Uses [repoAccessToken], else the stored
  /// token of [projectId], else none (public repos). Empty for a non-GitHub
  /// URL.
  Future<List<ProjectTool>> detectTools(
    Session session,
    String repoUrl, {
    String? repoAccessToken,
    int? projectId,
  }) async {
    final repo = parseGitHubRepoUrl(repoUrl);
    if (repo == null) return [];
    var token = repoAccessToken;
    if ((token == null || token.isEmpty) && projectId != null) {
      token = (await Project.db.findById(session, projectId))?.repoAccessToken;
    }
    if (token != null && token.isEmpty) token = null;
    final paths = await gitHubRepoClient.listRepoFiles(
      owner: repo.owner,
      repo: repo.repo,
      token: token,
    );
    return detectProjectTools(
      paths: paths,
      read: (path) => gitHubRepoClient.getRepoFile(
        owner: repo.owner,
        repo: repo.repo,
        path: path,
        token: token,
      ),
    );
  }

  /// Sets a new repo access token, keeping `scope=serverOnly` intact — the
  /// token itself is never echoed back, only the (non-sensitive)
  /// `repoAccessTokenUpdatedAt` timestamp is observable from the panel.
  Future<void> updateRepoAccessToken(
    Session session,
    int projectId,
    String token,
  ) async {
    var project = await Project.db.findById(session, projectId);
    if (project == null) {
      throw NotFoundException(message: 'Project $projectId not found');
    }
    await Project.db.updateRow(
      session,
      project.copyWith(
        repoAccessToken: token,
        repoAccessTokenUpdatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> delete(Session session, int id) async {
    await guardedDelete(session, (transaction) async {
      var project = await Project.db.findById(
        session,
        id,
        transaction: transaction,
      );
      if (project == null) {
        throw NotFoundException(message: 'Project $id not found');
      }

      var nonTerminalTaskCount = await Task.db.count(
        session,
        where: (t) =>
            t.projectId.equals(id) & t.status.inSet(nonTerminalTaskStatuses),
        transaction: transaction,
      );
      if (nonTerminalTaskCount > 0) {
        throw DeletionBlockedException(
          message: 'Cannot delete a project with non-terminal tasks',
          reason: DeletionBlockReason.nonTerminalTasks,
        );
      }

      await Project.db.deleteRow(session, project, transaction: transaction);
    });
  }

  /// Returns a ready-to-clone HTTPS URL for [projectId], with
  /// `repoAccessToken` (`scope=serverOnly`, never returned as its own field)
  /// injected as the userinfo component when present. Called by the agent
  /// daemon only at the moment a task starts, never persisted to disk on the
  /// agent side (docs/ARCHITECTURE.md).
  Future<String> getCloneUrl(Session session, int projectId) async {
    var project = await Project.db.findById(session, projectId);
    if (project == null) {
      throw NotFoundException(message: 'Project $projectId not found');
    }

    var token = project.repoAccessToken;
    if (token == null || token.isEmpty) {
      return project.repoUrl;
    }

    var uri = Uri.tryParse(project.repoUrl);
    if (uri == null || uri.scheme != 'https') {
      return project.repoUrl;
    }

    return uri.replace(userInfo: 'x-access-token:$token').toString();
  }
}
