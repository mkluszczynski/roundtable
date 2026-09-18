import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../client.dart';
import '../cubits/agent_list_cubit.dart';
import '../repositories/agent_repository.dart';

class AgentsScreen extends StatelessWidget {
  const AgentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AgentListCubit(AgentRepository(client))..fetchAgents(),
      child: BlocBuilder<AgentListCubit, AgentListState>(
        builder: (context, state) {
          return switch (state) {
            AgentListInitial() || AgentListLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            AgentListError(:final message) => Center(
              child: Text('Failed to load agents: $message'),
            ),
            AgentListLoaded(:final agents) =>
              agents.isEmpty
                  ? const Center(child: Text('No agents yet'))
                  : ListView.builder(
                      itemCount: agents.length,
                      itemBuilder: (context, index) {
                        final agent = agents[index];
                        return ListTile(
                          leading: const Icon(Icons.smart_toy),
                          title: Text(agent.name),
                          subtitle: Text(
                            '${agent.role.name} · ${agent.status.name}',
                          ),
                        );
                      },
                    ),
          };
        },
      ),
    );
  }
}
