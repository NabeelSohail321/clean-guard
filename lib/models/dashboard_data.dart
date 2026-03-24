class DashboardMetrics {
  final int totalInspections;
  final double averageScore;
  final int openIssues;
  final int resolvedIssues;
  final double avgAppaScore;
  final double avgResponseTime;

  DashboardMetrics({
    required this.totalInspections,
    required this.averageScore,
    required this.openIssues,
    required this.resolvedIssues,
    required this.avgAppaScore,
    required this.avgResponseTime,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      totalInspections: json['totalInspections'] ?? 0,
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      openIssues: json['openIssues'] ?? 0,
      resolvedIssues: json['resolvedIssues'] ?? 0,
      avgAppaScore: (json['avgAppaScore'] ?? 0).toDouble(),
      avgResponseTime: (json['avgResponseTime'] ?? 0).toDouble(),
    );
  }
}

class CheckpointData {
  final String date;
  final int count;
  final String fullDate;

  CheckpointData({
    required this.date,
    required this.count,
    required this.fullDate,
  });

  factory CheckpointData.fromJson(Map<String, dynamic> json) {
    return CheckpointData(
      date: json['date'] ?? '',
      count: json['count'] ?? 0,
      fullDate: json['date'] ?? '', // API returns date as fullDate in some endpoints
    );
  }
}
