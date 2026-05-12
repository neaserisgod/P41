class SessionUser {
  const SessionUser({
    required this.id,
    required this.name,
    required this.role,
    required this.initials,
    required this.branchIds,
    this.pin,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String role;
  final String initials;
  final List<String> branchIds;
  final String? pin;
  final bool isActive;

  SessionUser copyWith({
    String? id,
    String? name,
    String? role,
    String? initials,
    List<String>? branchIds,
    String? pin,
    bool clearPin = false,
    bool? isActive,
  }) {
    return SessionUser(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      initials: initials ?? this.initials,
      branchIds: branchIds ?? this.branchIds,
      pin: clearPin ? null : (pin ?? this.pin),
      isActive: isActive ?? this.isActive,
    );
  }
}

class SessionBranch {
  const SessionBranch({
    required this.id,
    required this.name,
    required this.label,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String label;
  final bool isActive;

  SessionBranch copyWith({
    String? id,
    String? name,
    String? label,
    bool? isActive,
  }) {
    return SessionBranch(
      id: id ?? this.id,
      name: name ?? this.name,
      label: label ?? this.label,
      isActive: isActive ?? this.isActive,
    );
  }
}
