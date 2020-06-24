import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'joint.dart';
import 'text_layout_cache.dart';
import 'truss.dart';

class TrussPainter extends CustomPainter {
  const TrussPainter({this.origin, this.scale, this.selectedJoint, this.showAddTruss});

  static const double eqh = 0.86602540378;

  static TextLayoutCache textCache = TextLayoutCache(TextDirection.ltr, 25);

  static Paint background = Paint()..color = const Color(0xFFF4F4F4);

  //static Paint background = Paint()..color = const Color(0xFF4A4A4A);
  static Paint gridPaint = Paint()
    ..color = const Color(0xFFCCCCCC)
    ..strokeWidth = 1;
  static Paint axesPaint = Paint()
    ..color = const Color(0xFFCCCCCC)
    ..strokeWidth = 3;
  static Paint trussPaint = Paint()
    ..color = Colors.deepOrange
    ..strokeWidth = 6;
  static Paint momentPaint = Paint()
    ..color = Colors.blueAccent
    ..strokeWidth = 6;
  static Paint ppfPain = Paint()
    ..color = Colors.red
    ..strokeWidth = 6;
  static Paint selPaint = Paint()
    ..color = Colors.lightGreen
    ..strokeWidth = 6;
  static Paint selIPaint = Paint()
    ..color = Colors.lightGreenAccent
    ..strokeWidth = 6;
  static Paint circleIPaint = Paint()..color = Colors.orange[100];
  static Paint exPaint = Paint()
    ..color = Colors.blueGrey[900]
    ..strokeWidth = 2;

  final Offset origin;
  final double scale;
  final int selectedJoint;
  final int showAddTruss;

  static TextPainter _addPaint1 = TextPainter(
      text: TextSpan(text: 'Select first joint position', style: TextStyle(color: Colors.white)),
      textAlign: TextAlign.left)
    ..textDirection = TextDirection.ltr
    ..layout();
  static TextPainter _addPaint2 = TextPainter(
      text: TextSpan(text: 'Select second joint position', style: TextStyle(color: Colors.white)),
      textAlign: TextAlign.left)
    ..textDirection = TextDirection.ltr
    ..layout();

  @override
  bool shouldRepaint(TrussPainter old) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    var sc = (size.width ~/ scale);

    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), background);

    // X-Axis
    canvas.drawLine(Offset(0, origin.dy), Offset(size.width, origin.dy), axesPaint);
    // Y-Axis
    canvas.drawLine(Offset(origin.dx, 0), Offset(origin.dx, size.height), axesPaint);

    // X-Grid
    for (var i = origin.dx.toInt() % sc; i < size.width; i += sc) {
      canvas.drawLine(Offset(i.toDouble(), 0), Offset(i.toDouble(), size.height), gridPaint);
    }
    // Y-Grid
    for (var i = origin.dy.toInt() % sc; i < size.height; i += sc) {
      canvas.drawLine(Offset(0, i.toDouble()), Offset(size.width, i.toDouble()), gridPaint);
    }

    // Connections
    Truss.all.values.forEach((Truss truss) {
      canvas.drawLine(origin.translate(truss.startX * sc, -truss.startY * sc),
          origin.translate(truss.endX * sc, -truss.endY * sc), trussPaint);
    });

    Joint.all.values.forEach((j) {
      var pt = selectedJoint == j.id ? selPaint : trussPaint;
      var ipt = selectedJoint == j.id ? selIPaint : circleIPaint;
      switch (j.type) {
        case JointType.STANDARD:
          //canvas.drawRect(Rect.fromCircle(center: origin.translate(j.x * sc, -j.y * sc), radius: 10), pt);
          canvas.drawCircle(origin.translate(j.x * sc, -j.y * sc), 10, pt);
          break;
        case JointType.PINNED:
          canvas.drawCircle(origin.translate(j.x * sc, -j.y * sc), 10, pt);
          var inner = Path()
            ..moveTo(origin.dx + j.x * sc - 6, origin.dy - j.y * sc + 4)
            ..relativeLineTo(12, 0)
            ..relativeLineTo(-6, -12 * eqh)
            ..close();
          //canvas.drawPath(tri, pt);
          canvas.drawPath(inner, ipt);
          break;
        case JointType.ROLLER_H:
          canvas.drawCircle(origin.translate(j.x * sc, -j.y * sc), 10, pt);
          canvas.drawCircle(origin.translate(j.x * sc, -j.y * sc), 6, ipt);
          break;
        case JointType.ROLLER_V:
          canvas.drawCircle(origin.translate(j.x * sc, -j.y * sc), 10, pt);
          canvas.drawCircle(origin.translate(j.x * sc, -j.y * sc), 6, ipt);
          break;
      }

      if (j.exDir != null && j.exAmount != null) {
        // draw external forces and force arrows
        var exX = j.exDir == AxisDirection.right ? 1 : j.exDir == AxisDirection.left ? -1 : 0.2;
        var exY = j.exDir == AxisDirection.down ? 1 : j.exDir == AxisDirection.up ? -1 : 0.2;
        if (j.exDir == AxisDirection.left || j.exDir == AxisDirection.right) {
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromPoints(origin.translate(j.x * sc + (12 * exX), -j.y * sc - (6 * exY)),
                      origin.translate(j.x * sc + (28 * exX), -j.y * sc + (6 * exY))),
                  Radius.circular(2)),
              exPaint);
          canvas.drawLine(origin.translate(j.x * sc + (28 * exX), -j.y * sc),
              origin.translate(j.x * sc + (22 * exX), -j.y * sc - 5), exPaint);
          canvas.drawLine(origin.translate(j.x * sc + (28 * exX), -j.y * sc),
              origin.translate(j.x * sc + (22 * exX), -j.y * sc + 5), exPaint);
          var tp = textCache.getOrPerformLayout(TextSpan(
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11.0),
              text: j.exAmount.toString()));
          tp.paint(canvas, origin.translate(j.x * sc + (20 * exX) - tp.width / 2, -j.y * sc + (22 * exY)));
        } else {
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromPoints(origin.translate(j.x * sc - (6 * exX), -j.y * sc + (12 * exY)),
                      origin.translate(j.x * sc + (6 * exX), -j.y * sc + (28 * exY))),
                  Radius.circular(2)),
              exPaint);
          canvas.drawLine(origin.translate(j.x * sc, -j.y * sc + (28 * exY)),
              origin.translate(j.x * sc - 5, -j.y * sc + (22 * exY)), exPaint);
          canvas.drawLine(origin.translate(j.x * sc, -j.y * sc + (28 * exY)),
              origin.translate(j.x * sc + 5, -j.y * sc + (22 * exY)), exPaint);
          var tp = textCache.getOrPerformLayout(TextSpan(
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11.0),
              text: j.exAmount.toString()));
          tp.paint(canvas, origin.translate(j.x * sc + (36 * exX), -j.y * sc + (18 * exY) - 5));
        }
      }

      var tp = textCache.getOrPerformLayout(TextSpan(
          style: TextStyle(color: Colors.lightBlue, fontWeight: FontWeight.bold, fontSize: 11.0),
          text: j.id.toString()));
      tp.paint(canvas, origin.translate(j.x * sc - 20, -j.y * sc - 12));

      if (j.moment != 0 && j.moment != null) {
        var tp = textCache.getOrPerformLayout(TextSpan(
            style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 11.0),
            text: j.moment.toStringAsFixed(2)));
        tp.paint(canvas, origin.translate(j.x * sc + 10, -j.y * sc));
      }

      if (j.reactionForce != 0 && j.reactionForce != null) {
        var tp = textCache.getOrPerformLayout(TextSpan(
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11.0),
            text: j.reactionForce.toStringAsFixed(2) +
                "\n" +
                ((j.reactionAngle / math.pi) * 180).toStringAsFixed(2) +
                "\nFrom " +
                j.sumaround.toString()));
        tp.paint(canvas, origin.translate(j.x * sc + 18, -j.y * sc + 14));
      }

      if (j.fx != null || j.fy != null) {
        var tp = textCache.getOrPerformLayout(TextSpan(
            style: TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold, fontSize: 11.0),
            text: "Fx: " +
                (j.fx?.toStringAsFixed(2) ?? "n/a") +
                "  Fy:" +
                (j.fy?.toStringAsFixed(2) ?? "n/a") +
                "\nPath " +
                j.codepath.toString()));
        tp.paint(canvas, origin.translate(j.x * sc - 10 - tp.width, -j.y * sc - 30));
      }
    });

    if (showAddTruss == 1) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(size.width / 2 - (_addPaint1.width + 12) / 2, 240, _addPaint1.width + 12, 30),
              Radius.circular(5)),
          trussPaint);
      _addPaint1.paint(canvas, Offset(size.width / 2 - (_addPaint1.width) / 2, 246));
    } else if (showAddTruss == 2) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(size.width / 2 - (_addPaint2.width + 12) / 2, 240, _addPaint2.width + 12, 30),
              Radius.circular(5)),
          trussPaint);
      _addPaint2.paint(canvas, Offset(size.width / 2 - (_addPaint2.width) / 2, 246));
    }
  }
}
