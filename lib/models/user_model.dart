class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.warehouseName,
    required this.role,
    required this.layout,
    required this.roles,
    required this.menu,
    required this.workspaces,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final String warehouseName;
  final String role;
  final String layout;
  final List<String> roles;
  final List<MenuItemModel> menu;
  final List<WorkspaceModel> workspaces;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      warehouseName: (json['warehouse_name'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      layout: (json['layout'] ?? '').toString(),
      roles: (json['roles'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      menu: (json['menu'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MenuItemModel.fromJson)
          .toList(),
      workspaces: (json['workspaces'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(WorkspaceModel.fromJson)
          .toList(),
    );
  }

  UserModel copyWith({
    String? role,
    String? layout,
    List<MenuItemModel>? menu,
    List<WorkspaceModel>? workspaces,
  }) {
    return UserModel(
      id: id,
      name: name,
      email: email,
      phone: phone,
      warehouseName: warehouseName,
      role: role ?? this.role,
      layout: layout ?? this.layout,
      roles: roles,
      menu: menu ?? this.menu,
      workspaces: workspaces ?? this.workspaces,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'warehouse_name': warehouseName,
    'role': role,
    'layout': layout,
    'roles': roles,
    'menu': menu.map((item) => item.toJson()).toList(),
    'workspaces': workspaces.map((item) => item.toJson()).toList(),
  };
}

class WorkspaceModel {
  const WorkspaceModel({
    required this.role,
    required this.layout,
    required this.label,
    required this.menu,
  });

  final String role;
  final String layout;
  final String label;
  final List<MenuItemModel> menu;

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceModel(
      role: (json['role'] ?? '').toString(),
      layout: (json['layout'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      menu: (json['menu'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MenuItemModel.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'role': role,
    'layout': layout,
    'label': label,
    'menu': menu.map((item) => item.toJson()).toList(),
  };
}

class MenuItemModel {
  const MenuItemModel({
    required this.key,
    required this.label,
    required this.route,
    required this.api,
    required this.icon,
    required this.group,
  });

  final String key;
  final String label;
  final String route;
  final String api;
  final String icon;
  final String group;

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      route: (json['route'] ?? '').toString(),
      api: (json['api'] ?? '').toString(),
      icon: (json['icon'] ?? '').toString(),
      group: (json['group'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'route': route,
    'api': api,
    'icon': icon,
    'group': group,
  };
}
