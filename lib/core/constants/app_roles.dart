class RoleOption {
  final String label;
  final String value;
  const RoleOption(this.label, this.value);
}

/// List of roles displayed in the UI (label) and the value sent to the API (value).
/// Update the `value` items to match the backend's accepted role identifiers.
const List<RoleOption> roleOptions = [
  // label -> value (value sent to backend)
  RoleOption('Quản trị viên trường', 'school'),
  RoleOption('Câu lạc bộ', 'club'),
  RoleOption('Người dùng thông thường', 'student'),
];

