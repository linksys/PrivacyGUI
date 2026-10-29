/// [path] with every TR-181 instance number replaced by `{i}`:
/// `Device.DHCPv4.Server.Pool.4.MinAddress` reads as
/// `Device.DHCPv4.Server.Pool.{i}.MinAddress`.
String pathTemplate(String path) =>
    path.replaceAll(RegExp(r'(?<=\.)\d+(?=\.)'), '{i}');

/// [params] with every key passed through [pathTemplate].
///
/// Lets a test pin which leaves a SET writes, and with which values, without
/// pinning the instance numbers the router happens to put them on.
Map<String, dynamic> paramTemplates(Map<String, dynamic> params) => {
      for (final entry in params.entries) pathTemplate(entry.key): entry.value,
    };
