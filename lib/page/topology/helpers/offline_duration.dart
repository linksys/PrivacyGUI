import 'package:privacy_gui/page/_shared/models/node_entity.dart';

/// The longest duration an offline extender can truthfully read.
///
/// hostmngr deletes a `Hosts` row 24 h after its host leaves
/// (`hosts.global.history_timeout` 86400 on FL-WRT 2.0), and an offline
/// extender is built from that row, so a real one is never shown for longer
/// than that. The hour on top absorbs the browser's clock running ahead of the
/// router's.
///
/// A longer duration can only come from a wrong stamp, most likely one the
/// router wrote before NTP set its clock. Right after a boot its clock has
/// been measured behind by about 19.5 h (2026-11-20) and by 2 h 20 min
/// (2026-11-23). Such a duration is shown as unknown rather than as a figure no
/// one measured. This catches only a stamp wrong enough to pass the retention;
/// a smaller error still reads as a figure, and nothing on the controller says
/// which stamps were written before NTP. One such case falls in a window the
/// page otherwise reads right: right after a clean controller reboot a node on
/// its way back has an inactive row for about 71–79 s, stamped with whatever
/// clock the controller has then. On a boot where NTP is late, that node can
/// read "Offline for 19 hrs" instead of "1 min". Not observed (the clock was
/// already right at that point on 2026-11-23), and not caught here.
///
/// Follows the firmware's retention: if `history_timeout` changes, this does.
const kMaxOfflineDuration = Duration(hours: 25);

/// How far ahead of the browser's clock a stamp may be and still read as the
/// shortest duration. Beyond it the stamp reads as unknown.
const kMaxFutureSkew = Duration(hours: 1);

/// How long [node] has been offline, for its Node Detail page (#1443, REQ-6a).
///
/// Null in four cases, each of which the page must not show as a duration:
/// - the node is online;
/// - it is the master, which has no offline shape (`MasterNode.isOnline` is
///   always true, and the controller's own `Hosts` stamp can be hours stale);
/// - it is offline but carries no usable stamp, which the page shows as
///   unknown, never as zero (AC3);
/// - the stamp is older than [kMaxOfflineDuration], so it cannot be right.
///
/// A stamp up to [kMaxFutureSkew] ahead of [now] means the browser clock is
/// behind the router's. It reads as zero rather than as a negative duration,
/// which [offlineDurationParts] shows as its shortest unit; further ahead it
/// reads as unknown.
///
/// Counted when the page builds, not on a timer: the page rebuilds when the
/// devices data changes, so on a quiet network the figure can stay where it
/// was for a while, as the page's other relative times do. Accepted (#1443).
Duration? nodeOfflineDuration(NodeEntity node, DateTime now) {
  if (node is! SlaveNode || node.isOnline) return null;
  final since = node.offlineSince;
  if (since == null) return null;
  final elapsed = now.toUtc().difference(since.toUtc());
  if (elapsed > kMaxOfflineDuration) return null;
  // Far in the future is no stamp either: a router clock that far ahead, or
  // a sentinel such as 9999-12-31, would otherwise read "1 min" for ever.
  if (elapsed < -kMaxFutureSkew) return null;
  return elapsed.isNegative ? Duration.zero : elapsed;
}

/// The unit [offlineDurationParts] reports a duration in.
enum OfflineDurationUnit { minutes, hours, days }

/// [elapsed] at the granularity the source supports (AC4).
///
/// - whole minutes below an hour, at least 1, so a node that has just gone
///   offline does not read "0 minutes";
/// - whole hours below two days;
/// - whole days after that.
///
/// [nodeOfflineDuration] never returns more than [kMaxOfflineDuration], so the
/// page reads minutes or hours; the days arm is for a firmware that keeps rows
/// longer.
///
/// The source does not support more precision than that. On FL-WRT 2.0
/// `ActiveLastChange` is last-change, not last-seen: it is written once when
/// the agent's row turns inactive, about 40 s after the agent's last contact,
/// so the true duration is a little longer than the one computed: at minute
/// granularity a node 2 min 10 s past its last contact can read "1 min". The
/// unit grows with the duration, so the error is at most one unit.
({int count, OfflineDurationUnit unit}) offlineDurationParts(Duration elapsed) {
  if (elapsed.inMinutes < 60) {
    final minutes = elapsed.inMinutes < 1 ? 1 : elapsed.inMinutes;
    return (count: minutes, unit: OfflineDurationUnit.minutes);
  }
  if (elapsed.inHours < 48) {
    return (count: elapsed.inHours, unit: OfflineDurationUnit.hours);
  }
  return (count: elapsed.inDays, unit: OfflineDurationUnit.days);
}
