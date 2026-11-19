// Plain data classes mirroring the API's JSON. Shared by the client and worker apps.

typedef Json = Map<String, dynamic>;

DateTime? _date(dynamic v) => v is String && v.isNotEmpty ? DateTime.tryParse(v)?.toLocal() : null;
List<String> _strings(dynamic v) => v is List ? v.map((e) => e.toString()).toList() : const [];
int _int(dynamic v, [int fallback = 0]) => v is num ? v.toInt() : int.tryParse('$v') ?? fallback;
String _str(dynamic v) => v == null ? '' : v.toString();

/// A populated reference comes back as an object; an unpopulated one as an id string.
String _refId(dynamic v) => v is Map ? _str(v['id']) : _str(v);
T? _obj<T>(dynamic v, T Function(Json) f) => v is Map ? f(Map<String, dynamic>.from(v)) : null;

// ---------------------------------------------------------------- Users

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.email = '',
    this.phone = '',
    this.profession = '',
    this.title = '',
    this.company = '',
    this.bio = '',
    this.location = '',
    this.yearsExperience = 0,
    this.avatarUrl = '',
    this.notificationsEnabled = true,
    this.trade = '',
    this.engineer,
    this.projects = const [],
  });

  final String id;
  final String name;
  final String role; // client | engineer | laborer
  final String email;
  final String phone;
  final String profession;
  final String title;
  final String company;
  final String bio;
  final String location;
  final int yearsExperience;
  final String avatarUrl;
  final bool notificationsEnabled;
  // Laborer-only
  final String trade;
  final AppUser? engineer;
  final List<ProjectLite> projects;

  bool get isEngineer => role == 'engineer';
  bool get isLaborer => role == 'laborer';
  bool get isClient => role == 'client';

  String get subtitle => title.isNotEmpty ? title : (profession.isNotEmpty ? profession : '');

  factory AppUser.fromJson(Json j) => AppUser(
        id: _str(j['id']),
        name: _str(j['name']),
        role: _str(j['role']),
        email: _str(j['email']),
        phone: _str(j['phone']),
        profession: _str(j['profession']),
        title: _str(j['title']),
        company: _str(j['company']),
        bio: _str(j['bio']),
        location: _str(j['location']),
        yearsExperience: _int(j['yearsExperience']),
        avatarUrl: _str(j['avatarUrl']),
        notificationsEnabled: j['notificationsEnabled'] != false,
        trade: _str(j['trade']),
        engineer: _obj(j['engineer'], AppUser.fromJson),
        projects: (j['projects'] as List? ?? []).whereType<Map>().map((e) => ProjectLite.fromJson(Map<String, dynamic>.from(e))).toList(),
      );
}

// ---------------------------------------------------------------- Projects

class ProjectLite {
  ProjectLite({required this.id, required this.name, this.location = '', this.status = '', this.coverImage = '', this.progress = 0});
  final String id;
  final String name;
  final String location;
  final String status;
  final String coverImage;
  final int progress;

  factory ProjectLite.fromJson(Json j) => ProjectLite(
        id: _str(j['id']),
        name: _str(j['name']),
        location: _str(j['location']),
        status: _str(j['status']),
        coverImage: _str(j['coverImage']),
        progress: _int(j['progress']),
      );
}

class ProjectFeedback {
  ProjectFeedback({required this.id, required this.rating, required this.text, required this.authorName, this.showOnPortfolio = true, this.createdAt});
  final String id;
  final int rating;
  final String text;
  final String authorName;
  final bool showOnPortfolio;
  final DateTime? createdAt;

  factory ProjectFeedback.fromJson(Json j) => ProjectFeedback(
        id: _str(j['id']),
        rating: _int(j['rating']),
        text: _str(j['text']),
        authorName: _str(j['authorName']),
        showOnPortfolio: j['showOnPortfolio'] != false,
        createdAt: _date(j['createdAt']),
      );
}

class Project {
  Project({
    required this.id,
    required this.name,
    this.location = '',
    this.address = '',
    this.description = '',
    this.coverImage = '',
    this.status = 'in_progress',
    this.progress = 0,
    this.startDate,
    this.expectedFinish,
    this.completedAt,
    this.budget,
    this.budgetVisible = true,
    this.inviteCode,
    this.lastUpdateAt,
    this.updatesCount = 0,
    this.photosCount = 0,
    this.peakLaborers = 0,
    this.openRequests = 0,
    this.engineerId = '',
    this.engineer,
    this.clients = const [],
    this.feedback = const [],
  });

  final String id;
  final String name;
  final String location;
  final String address;
  final String description;
  final String coverImage;
  final String status;
  final int progress;
  final DateTime? startDate;
  final DateTime? expectedFinish;
  final DateTime? completedAt;
  final num? budget; // null when hidden from this viewer
  final bool budgetVisible;
  final String? inviteCode; // engineer only
  final DateTime? lastUpdateAt;
  final int updatesCount;
  final int photosCount;
  final int peakLaborers;
  final int openRequests;
  final String engineerId;
  final AppUser? engineer;
  final List<AppUser> clients;
  final List<ProjectFeedback> feedback;

  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  AppUser? get primaryClient => clients.isEmpty ? null : clients.first;
  String get clientNames => clients.map((c) => c.name).join(', ');

  bool get updatedToday {
    final last = lastUpdateAt;
    if (last == null) return false;
    final now = DateTime.now();
    return last.year == now.year && last.month == now.month && last.day == now.day;
  }

  factory Project.fromJson(Json j) => Project(
        id: _str(j['id']),
        name: _str(j['name']),
        location: _str(j['location']),
        address: _str(j['address']),
        description: _str(j['description']),
        coverImage: _str(j['coverImage']),
        status: _str(j['status']).isEmpty ? 'in_progress' : _str(j['status']),
        progress: _int(j['progress']),
        startDate: _date(j['startDate']),
        expectedFinish: _date(j['expectedFinish']),
        completedAt: _date(j['completedAt']),
        budget: j['budget'] is num ? j['budget'] as num : null,
        budgetVisible: j['budgetVisible'] != false,
        inviteCode: j['inviteCode'] as String?,
        lastUpdateAt: _date(j['lastUpdateAt']),
        updatesCount: _int(j['updatesCount']),
        photosCount: _int(j['photosCount']),
        peakLaborers: _int(j['peakLaborers']),
        openRequests: _int(j['openRequests']),
        engineerId: _refId(j['engineer']),
        engineer: _obj(j['engineer'], AppUser.fromJson),
        clients: (j['clients'] as List? ?? []).whereType<Map>().map((e) => AppUser.fromJson(Map<String, dynamic>.from(e))).toList(),
        feedback: (j['feedback'] as List? ?? []).whereType<Map>().map((e) => ProjectFeedback.fromJson(Map<String, dynamic>.from(e))).toList(),
      );
}

// ---------------------------------------------------------------- Updates

class LaborerCount {
  LaborerCount(this.trade, this.count);
  final String trade;
  final int count;
  Json toJson() => {'trade': trade, 'count': count};
  factory LaborerCount.fromJson(Json j) => LaborerCount(_str(j['trade']), _int(j['count']));
}

class SiteUpdate {
  SiteUpdate({
    required this.id,
    required this.projectId,
    required this.date,
    this.projectName = '',
    this.authorKind = 'engineer',
    this.authorId = '',
    this.authorName = '',
    this.authorTrade = '',
    this.photos = const [],
    this.note = '',
    this.voiceNoteUrl = '',
    this.workTypes = const [],
    this.laborers = const [],
    this.totalLaborers = 0,
    this.progress,
    this.approvalCount = 0,
    this.approvedByMe = false,
    this.requestCount = 0,
    this.createdAt,
  });

  final String id;
  final String projectId;
  final String projectName;
  final DateTime date;
  final String authorKind;
  final String authorId;
  final String authorName;
  final String authorTrade;
  final List<String> photos;
  final String note;
  final String voiceNoteUrl;
  final List<String> workTypes;
  final List<LaborerCount> laborers;
  final int totalLaborers;
  final int? progress;
  final int approvalCount;
  final bool approvedByMe;
  final int requestCount;
  final DateTime? createdAt;

  bool get byLaborer => authorKind == 'laborer';

  String get summary {
    final parts = <String>[];
    if (photos.isNotEmpty) parts.add('${photos.length} photo${photos.length == 1 ? '' : 's'}');
    if (totalLaborers > 0) parts.add('$totalLaborers laborer${totalLaborers == 1 ? '' : 's'}');
    return parts.join(' · ');
  }

  factory SiteUpdate.fromJson(Json j) {
    final author = j['author'] is Map ? Map<String, dynamic>.from(j['author']) : <String, dynamic>{};
    return SiteUpdate(
      id: _str(j['id']),
      projectId: _refId(j['project']),
      projectName: _str(j['projectName']),
      date: _date(j['date']) ?? DateTime.now(),
      authorKind: _str(author['kind']).isEmpty ? 'engineer' : _str(author['kind']),
      authorId: _str(author['id']),
      authorName: _str(author['name']),
      authorTrade: _str(author['trade']),
      photos: _strings(j['photos']),
      note: _str(j['note']),
      voiceNoteUrl: _str(j['voiceNoteUrl']),
      workTypes: _strings(j['workTypes']),
      laborers: (j['laborers'] as List? ?? []).whereType<Map>().map((e) => LaborerCount.fromJson(Map<String, dynamic>.from(e))).toList(),
      totalLaborers: _int(j['totalLaborers']),
      progress: j['progress'] is num ? (j['progress'] as num).toInt() : null,
      approvalCount: (j['approvedBy'] as List?)?.length ?? 0,
      approvedByMe: j['approvedByMe'] == true,
      requestCount: _int(j['requestCount']),
      createdAt: _date(j['createdAt']),
    );
  }
}

class UpdateDetail {
  UpdateDetail({required this.update, required this.position, required this.total, this.prevId, this.nextId});
  final SiteUpdate update;
  final int position;
  final int total;
  final String? prevId;
  final String? nextId;

  factory UpdateDetail.fromJson(Json j) => UpdateDetail(
        update: SiteUpdate.fromJson(Map<String, dynamic>.from(j['update'])),
        position: _int(j['position'], 1),
        total: _int(j['total'], 1),
        prevId: j['prevId'] as String?,
        nextId: j['nextId'] as String?,
      );
}

// ---------------------------------------------------------------- Requests

class Reply {
  Reply({required this.id, required this.authorName, required this.authorRole, required this.message, this.createdAt});
  final String id;
  final String authorName;
  final String authorRole;
  final String message;
  final DateTime? createdAt;

  factory Reply.fromJson(Json j) => Reply(
        id: _str(j['id']),
        authorName: _str(j['authorName']),
        authorRole: _str(j['authorRole']),
        message: _str(j['message']),
        createdAt: _date(j['createdAt']),
      );
}

class ClientRequest {
  ClientRequest({
    required this.id,
    required this.type,
    required this.status,
    this.message = '',
    this.projectId = '',
    this.projectName = '',
    this.client,
    this.engineer,
    this.updateId,
    this.updateDate,
    this.updatePhoto,
    this.photos = const [],
    this.voiceNoteUrl = '',
    this.urgent = false,
    this.seenAt,
    this.resolvedAt,
    this.createdAt,
    this.replies = const [],
  });

  final String id;
  final String type; // question | change | approval | call
  final String status; // new | in_progress | done
  final String message;
  final String projectId;
  final String projectName;
  final AppUser? client;
  final AppUser? engineer;
  final String? updateId;
  final DateTime? updateDate;
  final String? updatePhoto;
  final List<String> photos;
  final String voiceNoteUrl;
  final bool urgent;
  final DateTime? seenAt;
  final DateTime? resolvedAt;
  final DateTime? createdAt;
  final List<Reply> replies;

  bool get isOpen => status != 'done';
  bool get isNew => status == 'new';

  factory ClientRequest.fromJson(Json j) {
    final project = j['project'];
    final update = j['update'];
    return ClientRequest(
      id: _str(j['id']),
      type: _str(j['type']),
      status: _str(j['status']),
      message: _str(j['message']),
      projectId: _refId(project),
      projectName: project is Map ? _str(project['name']) : '',
      client: _obj(j['client'], AppUser.fromJson),
      engineer: _obj(j['engineer'], AppUser.fromJson),
      updateId: update == null ? null : _refId(update),
      updateDate: update is Map ? _date(update['date']) : null,
      updatePhoto: update is Map && update['photos'] is List && (update['photos'] as List).isNotEmpty ? _str((update['photos'] as List).first) : null,
      photos: _strings(j['photos']),
      voiceNoteUrl: _str(j['voiceNoteUrl']),
      urgent: j['urgent'] == true,
      seenAt: _date(j['seenAt']),
      resolvedAt: _date(j['resolvedAt']),
      createdAt: _date(j['createdAt']),
      replies: (j['replies'] as List? ?? []).whereType<Map>().map((e) => Reply.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}

// ---------------------------------------------------------------- Laborers

class Laborer {
  Laborer({
    required this.id,
    required this.name,
    required this.phone,
    this.pin = '',
    this.trade = '',
    this.projects = const [],
    this.active = true,
    this.lastLoginAt,
  });

  final String id;
  final String name;
  final String phone;
  final String pin;
  final String trade;
  final List<ProjectLite> projects;
  final bool active;
  final DateTime? lastLoginAt;

  factory Laborer.fromJson(Json j) => Laborer(
        id: _str(j['id']),
        name: _str(j['name']),
        phone: _str(j['phone']),
        pin: _str(j['pin']),
        trade: _str(j['trade']),
        projects: (j['projects'] as List? ?? []).map((e) => e is Map ? ProjectLite.fromJson(Map<String, dynamic>.from(e)) : ProjectLite(id: _str(e), name: '')).toList(),
        active: j['active'] != false,
        lastLoginAt: _date(j['lastLoginAt']),
      );
}

// ---------------------------------------------------------------- Notifications

class AppNotification {
  AppNotification({required this.id, required this.type, required this.title, this.body = '', this.projectId, this.updateId, this.requestId, this.read = false, this.createdAt});
  final String id;
  final String type;
  final String title;
  final String body;
  final String? projectId;
  final String? updateId;
  final String? requestId;
  final bool read;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Json j) => AppNotification(
        id: _str(j['id']),
        type: _str(j['type']),
        title: _str(j['title']),
        body: _str(j['body']),
        projectId: j['project'] == null ? null : _refId(j['project']),
        updateId: j['update'] == null ? null : _refId(j['update']),
        requestId: j['request'] == null ? null : _refId(j['request']),
        read: j['read'] == true,
        createdAt: _date(j['createdAt']),
      );
}

// ---------------------------------------------------------------- Portfolio

class PortfolioCard {
  PortfolioCard({required this.id, required this.name, this.location = '', this.status = '', this.progress = 0, this.coverImage = '', this.completedAt, this.startDate, this.featured = false, this.hidden = false, this.visibleToClients = true});
  final String id;
  final String name;
  final String location;
  final String status;
  final int progress;
  final String coverImage;
  final DateTime? completedAt;
  final DateTime? startDate;
  final bool featured;
  final bool hidden;
  final bool visibleToClients;

  factory PortfolioCard.fromJson(Json j) => PortfolioCard(
        id: _str(j['id']),
        name: _str(j['name']),
        location: _str(j['location']),
        status: _str(j['status']),
        progress: _int(j['progress']),
        coverImage: _str(j['coverImage']),
        completedAt: _date(j['completedAt']),
        startDate: _date(j['startDate']),
        featured: j['featured'] == true,
        hidden: j['hidden'] == true,
        visibleToClients: j['visibleToClients'] != false,
      );
}

class CaseStudy {
  CaseStudy({
    required this.id,
    required this.name,
    this.location = '',
    this.status = '',
    this.progress = 0,
    this.startDate,
    this.completedAt,
    this.coverImage = '',
    this.durationMonths = 0,
    this.updates = 0,
    this.photos = 0,
    this.peakLaborers = 0,
    this.story = '',
    this.highlights = const [],
    this.feedback = const [],
    this.clientName,
    this.allPhotos = const [],
    this.featured = false,
    this.hidden = false,
    this.included = true,
    this.visibleToClients = true,
    this.showExactLocation = true,
    this.showClientName = false,
  });

  final String id;
  final String name;
  final String location;
  final String status;
  final int progress;
  final DateTime? startDate;
  final DateTime? completedAt;
  final String coverImage;
  final int durationMonths;
  final int updates;
  final int photos;
  final int peakLaborers;
  final String story;
  final List<String> highlights;
  final List<ProjectFeedback> feedback;
  final String? clientName;
  final List<String> allPhotos;
  final bool featured;
  final bool hidden;
  final bool included;
  final bool visibleToClients;
  final bool showExactLocation;
  final bool showClientName;

  factory CaseStudy.fromJson(Json j) {
    final stats = j['stats'] is Map ? Map<String, dynamic>.from(j['stats']) : <String, dynamic>{};
    final pf = j['portfolio'] is Map ? Map<String, dynamic>.from(j['portfolio']) : <String, dynamic>{};
    return CaseStudy(
      id: _str(j['id']),
      name: _str(j['name']),
      location: _str(j['location']),
      status: _str(j['status']),
      progress: _int(j['progress']),
      startDate: _date(j['startDate']),
      completedAt: _date(j['completedAt']),
      coverImage: _str(j['coverImage']),
      durationMonths: _int(stats['durationMonths']),
      updates: _int(stats['updates']),
      photos: _int(stats['photos']),
      peakLaborers: _int(stats['peakLaborers']),
      story: _str(j['story']),
      highlights: _strings(j['highlights']),
      feedback: (j['feedback'] as List? ?? []).whereType<Map>().map((e) => ProjectFeedback.fromJson(Map<String, dynamic>.from(e))).toList(),
      clientName: j['clientName'] as String?,
      allPhotos: _strings(j['allPhotos']),
      featured: pf['featured'] == true,
      hidden: pf['hidden'] == true,
      included: pf['included'] != false,
      visibleToClients: pf['visibleToClients'] != false,
      showExactLocation: pf['showExactLocation'] != false,
      showClientName: pf['showClientName'] == true,
    );
  }
}
