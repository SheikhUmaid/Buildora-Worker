import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api.dart';
import '../models/models.dart';
import 'auth.dart';

// ======================================================================= Queries

typedef FeedQuery = ({String? projectId, String? month, String? workType, String? q, bool mine});
typedef RequestQuery = ({String? status, String? projectId, String? updateId});

class ProjectDetail {
  ProjectDetail(this.project, this.latestUpdate);
  final Project project;
  final SiteUpdate? latestUpdate;
}

class RequestsResult {
  RequestsResult(this.requests, this.counts);
  final List<ClientRequest> requests;
  final Map<String, int> counts;
}

final dashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(apiProvider).get('/dashboard');
});

final projectsProvider = FutureProvider.autoDispose<List<Project>>((ref) async {
  final res = await ref.watch(apiProvider).get('/projects');
  return (res['projects'] as List).map((e) => Project.fromJson(e)).toList();
});

final projectDetailProvider = FutureProvider.autoDispose.family<ProjectDetail, String>((ref, id) async {
  final res = await ref.watch(apiProvider).get('/projects/$id');
  final latest = res['latestUpdate'];
  return ProjectDetail(Project.fromJson(res['project']), latest is Map<String, dynamic> ? SiteUpdate.fromJson(latest) : null);
});

final projectUpdatesProvider = FutureProvider.autoDispose.family<List<SiteUpdate>, String>((ref, projectId) async {
  final res = await ref.watch(apiProvider).get('/projects/$projectId/updates');
  return (res['updates'] as List).map((e) => SiteUpdate.fromJson(e)).toList();
});

final updatesFeedProvider = FutureProvider.autoDispose.family<List<SiteUpdate>, FeedQuery>((ref, q) async {
  final res = await ref.watch(apiProvider).get('/updates', query: {
    'projectId': q.projectId,
    'month': q.month,
    'workType': q.workType,
    'q': q.q,
    'mine': q.mine ? 'true' : null,
  });
  return (res['updates'] as List).map((e) => SiteUpdate.fromJson(e)).toList();
});

final updateDetailProvider = FutureProvider.autoDispose.family<UpdateDetail, String>((ref, id) async {
  return UpdateDetail.fromJson(await ref.watch(apiProvider).get('/updates/$id'));
});

final requestsProvider = FutureProvider.autoDispose.family<RequestsResult, RequestQuery>((ref, q) async {
  final res = await ref.watch(apiProvider).get('/requests', query: {'status': q.status, 'projectId': q.projectId, 'updateId': q.updateId});
  final counts = <String, int>{};
  (res['counts'] as Map? ?? {}).forEach((k, v) => counts['$k'] = (v as num).toInt());
  return RequestsResult((res['requests'] as List).map((e) => ClientRequest.fromJson(e)).toList(), counts);
});

final requestDetailProvider = FutureProvider.autoDispose.family<ClientRequest, String>((ref, id) async {
  final res = await ref.watch(apiProvider).get('/requests/$id');
  return ClientRequest.fromJson(res['request']);
});

final notificationsProvider = FutureProvider.autoDispose<(List<AppNotification>, int)>((ref) async {
  final res = await ref.watch(apiProvider).get('/notifications');
  return ((res['notifications'] as List).map((e) => AppNotification.fromJson(e)).toList(), (res['unread'] as num).toInt());
});

/// Unread notification count for badges (refreshes with notificationsProvider).
final unreadCountProvider = Provider.autoDispose<int>((ref) => ref.watch(notificationsProvider).value?.$2 ?? 0);

final metaProvider = FutureProvider<Map<String, List<String>>>((ref) async {
  final res = await ref.watch(apiProvider).get('/meta');
  return {
    for (final k in ['workTypes', 'trades', 'projectStatuses', 'requestTypes']) k: (res[k] as List).map((e) => '$e').toList(),
  };
});

// Engineer-side
final laborersProvider = FutureProvider.autoDispose<List<Laborer>>((ref) async {
  final res = await ref.watch(apiProvider).get('/laborers');
  return (res['laborers'] as List).map((e) => Laborer.fromJson(e)).toList();
});

final portfolioProvider = FutureProvider.autoDispose<(Map<String, dynamic>, List<PortfolioCard>)>((ref) async {
  final res = await ref.watch(apiProvider).get('/portfolio');
  return (Map<String, dynamic>.from(res['stats']), (res['projects'] as List).map((e) => PortfolioCard.fromJson(e)).toList());
});

final caseStudyProvider = FutureProvider.autoDispose.family<CaseStudy, String>((ref, projectId) async {
  final res = await ref.watch(apiProvider).get('/portfolio/$projectId');
  return CaseStudy.fromJson(res['project']);
});

// Client-side view of a contractor
class ContractorProfile {
  ContractorProfile(this.engineer, this.projectsWithYou, this.completed, this.stats);
  final AppUser engineer;
  final List<Project> projectsWithYou;
  final List<PortfolioCard> completed;
  final Map<String, dynamic> stats;
}

final contractorProvider = FutureProvider.autoDispose.family<ContractorProfile, String>((ref, engineerId) async {
  final res = await ref.watch(apiProvider).get('/engineers/$engineerId');
  return ContractorProfile(
    AppUser.fromJson(res['engineer']),
    (res['projectsWithYou'] as List).map((e) => Project.fromJson(e)).toList(),
    (res['completedProjects'] as List).map((e) => PortfolioCard.fromJson(e)).toList(),
    Map<String, dynamic>.from(res['stats'] ?? {}),
  );
});

final publicCaseStudyProvider = FutureProvider.autoDispose.family<CaseStudy, (String, String)>((ref, ids) async {
  final res = await ref.watch(apiProvider).get('/engineers/${ids.$1}/portfolio/${ids.$2}');
  return CaseStudy.fromJson(res['project']);
});

// ======================================================================= Mutations

final repoProvider = Provider<Repo>((ref) => Repo(ref));

/// All write operations. Each one invalidates the queries it affects.
class Repo {
  Repo(this.ref);
  final Ref ref;
  ApiClient get _api => ref.read(apiProvider);

  void refreshAll() {
    ref.invalidate(dashboardProvider);
    ref.invalidate(projectsProvider);
    ref.invalidate(projectDetailProvider);
    ref.invalidate(projectUpdatesProvider);
    ref.invalidate(updatesFeedProvider);
    ref.invalidate(updateDetailProvider);
    ref.invalidate(requestsProvider);
    ref.invalidate(requestDetailProvider);
    ref.invalidate(notificationsProvider);
  }

  // ---------- Projects
  Future<Project> createProject(Map<String, dynamic> fields, {String? coverPath}) async {
    final res = await _api.multipart('POST', '/projects', fields: fields, files: {if (coverPath != null) 'cover': [coverPath]});
    refreshAll();
    return Project.fromJson(res['project']);
  }

  Future<Project> editProject(String id, Map<String, dynamic> fields, {String? coverPath}) async {
    final res = await _api.multipart('PATCH', '/projects/$id', fields: fields, files: {if (coverPath != null) 'cover': [coverPath]});
    refreshAll();
    ref.invalidate(caseStudyProvider);
    return Project.fromJson(res['project']);
  }

  Future<void> deleteProject(String id) async {
    await _api.delete('/projects/$id');
    refreshAll();
    ref.invalidate(portfolioProvider);
  }

  Future<void> setProjectStatus(String id, String status) async {
    await _api.patch('/projects/$id/status', {'status': status});
    refreshAll();
    ref.invalidate(portfolioProvider);
  }

  Future<void> setProjectProgress(String id, int progress) async {
    await _api.patch('/projects/$id/progress', {'progress': progress});
    refreshAll();
  }

  Future<String> regenerateInviteCode(String id) async {
    final res = await _api.post('/projects/$id/invite-code');
    refreshAll();
    return res['inviteCode'] as String;
  }

  Future<void> removeClient(String projectId, String clientId) async {
    await _api.delete('/projects/$projectId/clients/$clientId');
    refreshAll();
  }

  Future<Project> joinProject(String code) async {
    final res = await _api.post('/projects/join', {'code': code.trim().toUpperCase()});
    refreshAll();
    return Project.fromJson(res['project']);
  }

  Future<void> leaveProject(String id) async {
    await _api.post('/projects/$id/leave');
    refreshAll();
  }

  Future<void> sendFeedback(String projectId, int rating, String text) async {
    await _api.post('/projects/$projectId/feedback', {'rating': rating, 'text': text});
    refreshAll();
  }

  // ---------- Updates
  Future<SiteUpdate> postUpdate(
    String projectId, {
    required List<String> photos,
    String note = '',
    String? voicePath,
    DateTime? date,
    List<String> workTypes = const [],
    List<LaborerCount> laborers = const [],
    int? totalLaborers,
    int? progress,
    void Function(double)? onProgress,
  }) async {
    final res = await _api.multipart(
      'POST',
      '/projects/$projectId/updates',
      fields: {
        'note': note,
        if (date != null) 'date': date.toIso8601String(),
        'workTypes': _jsonList(workTypes),
        'laborers': _jsonLaborers(laborers),
        'totalLaborers': ?totalLaborers,
        'progress': ?progress,
      },
      files: {'photos': photos, if (voicePath != null) 'voiceNote': [voicePath]},
      onProgress: onProgress,
    );
    refreshAll();
    ref.invalidate(portfolioProvider);
    return SiteUpdate.fromJson(res['update']);
  }

  Future<void> editUpdate(
    String id, {
    String? note,
    List<String> newPhotos = const [],
    List<String> removePhotos = const [],
    String? voicePath,
    bool removeVoice = false,
    int? totalLaborers,
  }) async {
    await _api.multipart(
      'PATCH',
      '/updates/$id',
      fields: {
        'note': ?note,
        if (removePhotos.isNotEmpty) 'removePhotos': _jsonList(removePhotos),
        if (removeVoice) 'removeVoiceNote': 'true',
        'totalLaborers': ?totalLaborers,
      },
      files: {'photos': newPhotos, if (voicePath != null) 'voiceNote': [voicePath]},
    );
    refreshAll();
  }

  Future<void> deleteUpdate(String id) async {
    await _api.delete('/updates/$id');
    refreshAll();
  }

  // ---------- Requests
  Future<ClientRequest> createRequest({
    required String projectId,
    String? updateId,
    required String type,
    String message = '',
    bool urgent = false,
    List<String> photos = const [],
    String? voicePath,
  }) async {
    final res = await _api.multipart(
      'POST',
      '/requests',
      fields: {'projectId': projectId, 'updateId': ?updateId, 'type': type, 'message': message, 'urgent': urgent},
      files: {'photos': photos, if (voicePath != null) 'voiceNote': [voicePath]},
    );
    refreshAll();
    return ClientRequest.fromJson(res['request']);
  }

  Future<ClientRequest> reply(String requestId, String message, {String? status}) async {
    final res = await _api.post('/requests/$requestId/replies', {'message': message, 'status': ?status});
    refreshAll();
    return ClientRequest.fromJson(res['request']);
  }

  Future<void> setRequestStatus(String requestId, String status) async {
    await _api.patch('/requests/$requestId/status', {'status': status});
    refreshAll();
  }

  Future<void> withdrawRequest(String requestId) async {
    await _api.delete('/requests/$requestId');
    refreshAll();
  }

  // ---------- Notifications
  Future<void> markAllRead() async {
    await _api.post('/notifications/read-all');
    ref.invalidate(notificationsProvider);
  }

  Future<void> markRead(String id) async {
    await _api.post('/notifications/$id/read');
    ref.invalidate(notificationsProvider);
  }

  // ---------- Laborers (engineer)
  Future<Laborer> addLaborer(Map<String, dynamic> body) async {
    final res = await _api.post('/laborers', body);
    ref.invalidate(laborersProvider);
    return Laborer.fromJson(res['laborer']);
  }

  Future<Laborer> editLaborer(String id, Map<String, dynamic> body) async {
    final res = await _api.patch('/laborers/$id', body);
    ref.invalidate(laborersProvider);
    return Laborer.fromJson(res['laborer']);
  }

  Future<Laborer> resetPin(String id) async {
    final res = await _api.post('/laborers/$id/reset-pin');
    ref.invalidate(laborersProvider);
    return Laborer.fromJson(res['laborer']);
  }

  Future<void> deleteLaborer(String id) async {
    await _api.delete('/laborers/$id');
    ref.invalidate(laborersProvider);
  }

  // ---------- Portfolio (engineer)
  Future<void> updatePortfolio(String projectId, Map<String, dynamic> body) async {
    await _api.patch('/portfolio/$projectId', body);
    ref.invalidate(caseStudyProvider(projectId));
    ref.invalidate(portfolioProvider);
  }

  Future<void> uploadPortfolioPhotos(String projectId, List<String> paths) async {
    await _api.multipart('POST', '/portfolio/$projectId/photos', files: {'photos': paths});
    ref.invalidate(caseStudyProvider(projectId));
    ref.invalidate(portfolioProvider);
  }

  Future<void> setFeedbackVisibility(String projectId, String feedbackId, bool show) async {
    await _api.patch('/portfolio/$projectId/feedback/$feedbackId', {'showOnPortfolio': show});
    ref.invalidate(caseStudyProvider(projectId));
  }

  // ---------- Password reset
  Future<String?> forgotPassword(String email) async {
    final res = await _api.post('/auth/forgot-password', {'email': email.trim()});
    return res['devCode'] as String?;
  }

  Future<void> resetPassword(String email, String code, String password) =>
      _api.post('/auth/reset-password', {'email': email.trim(), 'code': code.trim(), 'newPassword': password});
}

String _jsonList(List<String> items) => jsonEncode(items);
String _jsonLaborers(List<LaborerCount> items) => jsonEncode(items.map((l) => l.toJson()).toList());
