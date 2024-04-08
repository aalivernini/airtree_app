import 'package:flutter/material.dart';

enum Direction {up, down, left, right}

class MakeCircle extends CustomPainter {
    final double strokeWidth;
    final StrokeCap strokeCap;
    final double radius;
    Color color;

    MakeCircle({this.strokeCap = StrokeCap.square, this.strokeWidth = 3.0, this.radius = 40.0, this.color = Colors.white});

    @override
    void paint(Canvas canvas, Size size) {
        final paint = Paint()
                ..color = color
                ..strokeCap = StrokeCap.round
                ..strokeWidth = strokeWidth
                ..style = PaintingStyle.stroke; //important set stroke style
        //var position =  Offset(radius/2, radius/2);
        var position =  Offset(0, 0);
        //var position =  Offset(radius, radius);
        //var position =  const Offset(0, 0);
        canvas.drawCircle(position, radius, paint);
    }

    @override
    bool shouldRepaint(CustomPainter oldDelegate) => false;
}


class AccuracyIndicator extends CustomPainter {
    final double diffVertical;       // (tilt - laiAngle) * tiltSign
    final double diffHorizontal;    // tiltOrto
    final double tolerance;

    AccuracyIndicator({required this.diffVertical, required this.diffHorizontal, this.tolerance = 1});

    @override
    void paint(Canvas canvas, Size size) {
        const strokeCap = StrokeCap.round;
        double s1 = 60;
        double s2 = 14;
        double s3 = 10;

        double strokeWidth1 = 2;
        double strokeWidth2 = 4;

        Color color1 = Colors.white;

        // outer circle
        var position =  Offset(0, 0);
        //var position =  Offset(s1, s1);
        final paint1 = Paint()
                ..color = color1
                ..strokeCap = strokeCap
                ..strokeWidth = strokeWidth1
                ..style = PaintingStyle.stroke; //important set stroke style
        canvas.drawCircle(position, s1, paint1);

        // ok circle
        //position =  Offset(s2, s2);
        canvas.drawCircle(position, s2, paint1);

        // current tilt position
        Color color2;
        if (diffVertical.abs() < tolerance ) {
            color2 = Colors.blue;
        }
        else {
            color2 = Colors.white;
        }

        double hOffset = (diffHorizontal  / 5) * 3 * 10;
        double vOffset = (diffVertical / 5 * 3) * 10;

        final paint2 = Paint()
                ..color = color2
                ..strokeCap = strokeCap
                ..strokeWidth = strokeWidth2
                ..style = PaintingStyle.stroke; //important set stroke style
        //position =  Offset(s3 + hOffset, s3 + vOffset);
        position =  Offset(hOffset, vOffset);
        canvas.drawCircle(position, s3, paint2);


    }

    @override
    bool shouldRepaint(CustomPainter oldDelegate) => false;
}





class TrianglePainter extends CustomPainter {
    final Color strokeColor;
    final PaintingStyle paintingStyle;
    final double strokeWidth;
    Direction direction;

    TrianglePainter({this.strokeColor = Colors.black, this.strokeWidth = 3, this.paintingStyle = PaintingStyle.stroke, this.direction = Direction.up});

    @override
    void paint(Canvas canvas, Size size) {
        Paint paint = Paint()
                ..color = strokeColor
                ..strokeWidth = strokeWidth
                ..strokeCap = StrokeCap.round
                ..style = paintingStyle;

        canvas.drawPath(getTrianglePath(size.width, size.height), paint);
    }

    Path getTrianglePath(double x, double y) {
        if (direction == Direction.down){
            return Path()
                    ..moveTo(0, 0)
                    ..lineTo(x, 0)
                    ..lineTo(x / 2, y)
                    ..lineTo(0, 0);
        }
        else if (direction == Direction.up) {
            return Path()
                    ..moveTo(0, y)
                    ..lineTo(x, y)
                    ..lineTo(x / 2, 0)
                    ..lineTo(0, y);
        }
        else if (direction == Direction.left) {
            return Path()
                    ..moveTo(0, 0)
                    ..lineTo(0, y)
                    ..lineTo(x, y / 2)
                    ..lineTo(0, 0);
        }
        else if (direction == Direction.right) {
            return Path()
                    ..moveTo(x, 0)
                    ..lineTo(x, y)
                    ..lineTo(0, y / 2)
                    ..lineTo(x, 0);
        }
        else {
            return Path()
                    ..moveTo(0, y)
                    ..lineTo(x / 2, 0)
                    ..lineTo(x, y)
                    ..lineTo(0, y);
        }
    }

    @override
    bool shouldRepaint(CustomPainter oldDelegate) => false;
}
