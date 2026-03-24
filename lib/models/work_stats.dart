class WorkStatsResponse {
  final WorkStatsSummary summary;
  final List<UserStats> userStats;
  final List<SupervisorData> supervisors;
  final List<WorkActivity> activity;

  WorkStatsResponse({
    required this.summary,
    required this.userStats,
    required this.supervisors,
    required this.activity,
  });

  factory WorkStatsResponse.fromJson(Map<String, dynamic> json) {
    return WorkStatsResponse(
      summary: WorkStatsSummary.fromJson(json['summary'] ?? {}),
      userStats: (json['userStats'] as List?)
              ?.map((e) => UserStats.fromJson(e))
              .toList() ??
          [],
      supervisors: (json['supervisors'] as List?)
              ?.map((e) => SupervisorData.fromJson(e))
              .toList() ??
          [],
      activity: (json['activity'] as List?)
              ?.map((e) => WorkActivity.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class WorkStatsSummary {
  final int totalTickets;
  final int totalTicketsResolved;
  final double? avgTicketResolutionHours;
  final int totalInspections;
  final int totalInspectionsCompleted;
  final double? avgInspectionScore;

  WorkStatsSummary({
    this.totalTickets = 0,
    this.totalTicketsResolved = 0,
    this.avgTicketResolutionHours,
    this.totalInspections = 0,
    this.totalInspectionsCompleted = 0,
    this.avgInspectionScore,
  });

  factory WorkStatsSummary.fromJson(Map<String, dynamic> json) {
    return WorkStatsSummary(
      totalTickets: json['totalTickets'] ?? 0,
      totalTicketsResolved: json['totalTicketsResolved'] ?? 0,
      avgTicketResolutionHours:
          (json['avgTicketResolutionHours'] as num?)?.toDouble(),
      totalInspections: json['totalInspections'] ?? 0,
      totalInspectionsCompleted: json['totalInspectionsCompleted'] ?? 0,
      avgInspectionScore: (json['avgInspectionScore'] as num?)?.toDouble(),
    );
  }
}

class UserStats {
  final String userId;
  final String name;
  final String role;
  final UserTicketsStats tickets;
  final UserInspectionsStats inspections;

  UserStats({
    required this.userId,
    required this.name,
    required this.role,
    required this.tickets,
    required this.inspections,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      tickets: UserTicketsStats.fromJson(json['tickets'] ?? {}),
      inspections: UserInspectionsStats.fromJson(json['inspections'] ?? {}),
    );
  }
}

class UserTicketsStats {
  final int assigned;
  final int started;
  final int resolved;
  final double? avgResolutionHours;

  UserTicketsStats({
    this.assigned = 0,
    this.started = 0,
    this.resolved = 0,
    this.avgResolutionHours,
  });

  factory UserTicketsStats.fromJson(Map<String, dynamic> json) {
    return UserTicketsStats(
      assigned: json['assigned'] ?? 0,
      started: json['started'] ?? 0,
      resolved: json['resolved'] ?? 0,
      avgResolutionHours: (json['avgResolutionHours'] as num?)?.toDouble(),
    );
  }
}

class UserInspectionsStats {
  final int assigned;
  final int completed;
  final double avgScore;
  final double? avgCompletionHours;

  UserInspectionsStats({
    this.assigned = 0,
    this.completed = 0,
    this.avgScore = 0.0,
    this.avgCompletionHours,
  });

  factory UserInspectionsStats.fromJson(Map<String, dynamic> json) {
    return UserInspectionsStats(
      assigned: json['assigned'] ?? 0,
      completed: json['completed'] ?? 0,
      avgScore: (json['avgScore'] as num?)?.toDouble() ?? 0.0,
      avgCompletionHours: (json['avgCompletionHours'] as num?)?.toDouble(),
    );
  }
}

class SupervisorData {
  final String id;
  final String name;
  final String role;

  SupervisorData({
    required this.id,
    required this.name,
    required this.role,
  });

  factory SupervisorData.fromJson(Map<String, dynamic> json) {
    return SupervisorData(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
    );
  }
}

class WorkActivity {
  final String type; // 'ticket' or 'inspection'
  final String id;
  final String title;
  final String locationName;
  final String person; // Person name
  final String? status;
  final String? startedAt;
  final String? completedAt;
  final double? timeTakenHours;
  final String? createdAt;

  WorkActivity({
    required this.type,
    required this.id,
    required this.title,
    required this.locationName,
    required this.person,
    this.status,
    this.startedAt,
    this.completedAt,
    this.timeTakenHours,
    this.createdAt,
  });

  factory WorkActivity.fromJson(Map<String, dynamic> json) {
    return WorkActivity(
      type: json['type'] ?? '',
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      locationName: json['locationName'] ?? '',
      person: json['person'] ?? '',
      status: json['status'],
      startedAt: json['startedAt'],
      completedAt: json['completedAt'],
      timeTakenHours: (json['timeTakenHours'] as num?)?.toDouble(),
      createdAt: json['createdAt'],
    );
  }
}
