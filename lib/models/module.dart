class Module {
  final String id;
  final String name;
  final String sectionName;
  final List<String> programs;
  final bool isActive;

  Module({
    required this.id,
    required this.name,
    required this.sectionName,
    required this.programs,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sectionName': sectionName,
      'programs': programs,
      'isActive': isActive,
    };
  }

  factory Module.fromMap(String id, Map<String, dynamic> map) {
    return Module(
      id: id,
      name: map['name'] ?? '',
      sectionName: map['sectionName'] ?? 'Sin Sección',
      programs: List<String>.from(map['programs'] ?? []),
      isActive: map['isActive'] ?? true,
    );
  }
}
