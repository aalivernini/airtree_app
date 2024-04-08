import 'dart:math';

class Colour {

    List<double> rgb2hsv(int r, int g, int b){

        final red =   ( r.toDouble() / 255.0 );
        final green = ( g.toDouble() / 255.0 );
        final blue =  ( b.toDouble() / 255.0 );

        var min     = red < green ? red : green;
        min         = min < blue ? min : blue;
        var max     = red > green ? red : green;
        max         = max > blue ? max : blue;
        final deltaMax = max - min;

        var h   = 0.0;
        var s   = 0.0;
        final v = max;

        if ( deltaMax > 0 )               
        {
            s = deltaMax / max;
            final deltaR = _hsvFun(max, deltaMax, red);
            final deltaG = _hsvFun(max, deltaMax, green);
            final deltaB = _hsvFun(max, deltaMax, blue);

            if      ( red == max )  {h = deltaB - deltaG;}
            else if ( green == max ) {h = ( 1.0 / 3.0 ) + deltaR - deltaB;}
            else if ( blue == max ) {h = ( 2.0 / 3.0 ) + deltaG - deltaR;}
            if ( h < 0 ) h += 1;
            if ( h > 1 ) h -= 1;

            if ( h < 0 ) h += 1;
            if ( h > 1 ) h -= 1;
        }
        return [h, s, v];
    }




    List<double> rgb2xyz(int r, int g, int b){
        // http://www.easyrgb.com/en/math.php#text2
        num red = (r.toDouble() / 255.0);
        num blue = (b.toDouble() / 255.0);
        num green = (g.toDouble() / 255.0);

        red   = _rgbFun(red);
        green = _rgbFun(green);
        blue  = _rgbFun(blue);

        final X = red * 0.4124 + green * 0.3576 + blue * 0.1805;
        final Y = red * 0.2126 + green * 0.7152 + blue * 0.0722;
        final Z = red * 0.0193 + green * 0.1192 + blue * 0.9505;

        return [X,Y,Z];

    }


    List<double> rgb2lab(int r, int g, int bb){
        //http://www.easyrgb.com/en/math.php#text7
        var xyz = rgb2xyz(r, g, bb);

        // D65 (daylight) CIE 1964
        num x = xyz[0] / 94.811;  
        num y = xyz[1] / 100.000; 
        num z = xyz[2] / 107.304; 

        x = _labFun(x);
        y = _labFun(y);
        z = _labFun(z);

        final l = (116.0 * y ) - 16;
        final a =  500.0 * ( x - y );
        final b =  200.0 * ( y - z );

        return [l,a,b];
    }

    double _hsvFun(double max, double delta, double value){
        return ( ( ( max - value ) / 6.0 ) + ( delta / 2.0 ) ) / delta;
    }

    num _rgbFun(num x){
        if ( x > 0.04045 ) {
            x = pow((( x + 0.055 ) / 1.055 ),  2.4);
        }
        else {
            x = x / 12.92;
        }
        return x * 100;
    }

    num _labFun(num x){
        if ( x > 0.008856 ) {
            x = pow(x, 1/3);
        } else {
            x =  (7.787 * x) + (16.0 / 116.0);
        }
        return x;
    }

}



