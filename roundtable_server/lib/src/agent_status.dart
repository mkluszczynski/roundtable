import 'package:serverpod/serverpod.dart';

import 'generated/protocol.dart';

/// Channel every agent change is posted to, streamed to the panel by
/// `AgentEndpoint.watchAgents` so agent statuses stay live.
const allAgentsChannel = 'all-agents';

/// Broadcasts agent [agentId]'s current row (with its role, like
/// `AgentEndpoint.list`) to `AgentEndpoint.watchAgents` subscribers. Call
/// after every write to an agent row.
Future<void> postAgentChanged(Session session, int agentId) async {
  var agent = await Agent.db.findById(
    session,
    agentId,
    include: Agent.include(role: AgentRoleDefinition.include()),
  );
  if (agent == null) return;
  await session.messages.postMessage(allAgentsChannel, agent);
}

/// Task statuses in which the agent's `claude` process is running.
const _workingTaskStatuses = {
  TaskStatus.cloning,
  TaskStatus.planning,
  TaskStatus.running,
};

/// The status to store when [requested] is reported for [agentId]. An agent
/// can run a task and a code review at the same time (the runner handles
/// them independently), so the one finishing first mustn't mark the agent
/// `idle` while the other is still going: `idle` becomes `busy` (or
/// `waitingForResponse`) while the agent still has a working task or a
/// running review. Other statuses are stored as reported.
Future<AgentStatus> settledAgentStatus(
  Session session,
  int agentId,
  AgentStatus requested,
) async {
  if (requested != AgentStatus.idle) return requested;
  final working = await Task.db.count(
    session,
    where: (t) =>
        t.agentId.equals(agentId) & t.status.inSet(_workingTaskStatuses),
  );
  if (working > 0) return AgentStatus.busy;
  final reviewing = await CodeReview.db.count(
    session,
    where: (r) =>
        r.reviewerAgentId.equals(agentId) &
        r.status.equals(CodeReviewStatus.running),
  );
  if (reviewing > 0) return AgentStatus.busy;
  final waiting = await Task.db.count(
    session,
    where: (t) =>
        t.agentId.equals(agentId) &
        t.status.equals(TaskStatus.waitingForAnswer),
  );
  return waiting > 0 ? AgentStatus.waitingForResponse : AgentStatus.idle;
}
