import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'joint.dart';

class Truss {
  static int _ids = 0;
  static Map<int, Truss> all = Map();

  static Iterable<Truss> embeddable(Joint j) => all.values.toList().where((t) {
        if (t.endId == j.id || t.startId == j.id) return false;
        if (t.startX == j.x && t.startY == j.y) return false;
        if (t.endX == j.x && t.endY == j.y) return false;
        var ab = Offset(t.startX - t.endX, t.startY - t.endY);
        var ac = Offset(t.startX - j.x, t.startY - j.y);
        var bc = Offset(t.endX - j.x, t.endY - j.y);
        return (ab.distance + 0.000001 > (ac.distance + bc.distance) &&
            ab.distance - 0.000001 < (ac.distance + bc.distance));
      });

  static void embed(Joint j) => embeddable(j).forEach((t) {
        t.delete();
        Truss(t.startId, j.id);
        Truss(j.id, t.endId);
      });

  Truss._(this._id, this.startId, this.endId);

  factory Truss(int startJoint, int endJoint) {
    var truss = Truss._(_ids++, startJoint, endJoint);
    all[truss._id] = truss;
    return truss;
  }

  factory Truss.auto(double startX, double startY, double endX, double endY) =>
      Truss(Joint(startX, startY, JointType.STANDARD).id, Joint(endX, endY, JointType.STANDARD).id);

  factory Truss.joinStart(Joint start, double endX, double endY) =>
      Truss(start.id, Joint(endX, endY, JointType.STANDARD).id);

  Truss chainStart(double endX, double endY) => Truss.joinStart(startJoint, endX, endY);

  void delete() {
    all.remove(_id);
  }

  final int _id;
  final int startId;
  final int endId;

  Joint get startJoint => Joint.all[startId];

  Joint get endJoint => Joint.all[endId];

  double get startX => startJoint.x;

  double get startY => startJoint.y;

  double get endX => endJoint.x;

  double get endY => endJoint.y;

  double get angle => math.atan2(endY - endX, startY - startX);
  double get angleN => math.atan((endY - endX) / (startY - startX));

  double get dyDx => (endY - startY) / (endX - startX);

  static int get maxId => _ids;

  int calcStep = 0;

  @override
  String toString() {
    return 'Truss{id: $_id, startPin: $startId, endPin: $endId}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Truss && runtimeType == other.runtimeType && startId == other.startId && endId == other.endId;

  @override
  int get hashCode => _id;
}
