import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../client.dart';
import '../cubits/project_list_cubit.dart';
import '../repositories/project_repository.dart';
import '../widgets/create_task_dialog.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ProjectListCubit(ProjectRepository(client))..fetchProjects(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add_task),
          label: const Text('New Task'),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const CreateTaskDialog(),
          ),
        ),
        body: BlocBuilder<ProjectListCubit, ProjectListState>(
          builder: (context, state) {
            return switch (state) {
              ProjectListInitial() || ProjectListLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              ProjectListError(:final message) => Center(
                child: Text('Failed to load projects: $message'),
              ),
              ProjectListLoaded(:final projects) =>
                projects.isEmpty
                    ? const Center(child: Text('No projects yet'))
                    : ListView.builder(
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final project = projects[index];
                          return ListTile(
                            leading: const Icon(Icons.folder),
                            title: Text(project.name),
                            subtitle: Text(project.repoUrl),
                          );
                        },
                      ),
            };
          },
        ),
      ),
    );
  }
}
