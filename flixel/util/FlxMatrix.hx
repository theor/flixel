package flixel.util;

// TODO: move this class to flixel.math package

/**
 * Helper class for making fast matrix calculations for rendering.
 * It mostly copies Matrix class, but with some additions for
 * faster rotation by 90 degrees.
 */
class FlxMatrix
{
	/**
	 * Helper object, which you can use without instantiation of
	 * additional objects.
	 */
	public static var matrix:FlxMatrix = new FlxMatrix();
	
	/**
	 * Just transformation coeeficient
	 */
	public var a:Float = 0;
	public var b:Float = 0;
	public var c:Float = 0;
	public var d:Float = 0;
	
	/**
	 * Matrix constructor, just initializes matrix coefficients.
	 * Nothing fancy.
	 */
	public function new(a:Float = 1, b:Float = 0, c:Float = 0, d:Float = 1) 
	{  
		this.set(a, b, c, d);
	}
	
	/**
	 * Set matrix coeeficients in one step
	 */
	public inline function set(a:Float, b:Float, c:Float, d:Float):FlxMatrix
	{
		this.a = a;
		this.b = b;
		this.c = c;
		this.d = d;
		
		return this;
	}
	
	/**
	 * Applies tranformation of this matrix to specified point
	 * @param	point	FlxPoint to transform
	 * @return	transformed point
	 */
	public inline function rotatePoint(point:FlxPoint):FlxPoint
	{
		var x:Float = point.x * a + point.y * c;
		var y:Float = point.x * b + point.y * d;
		
		return point.set(x, y);
	}
	
	/**
	 * Applies rotation to this matrix.
	 */
	public inline function rotate(radians:Float):FlxMatrix
	{
		var cos:Float = Math.cos(radians);
		var sin:Float = Math.sin(radians);
		
		return this.rotateWithTrig(cos, sin);
	}
	
	/**
	 * Rotates this matrix, but takes the values of sine and cosine,
	 * so it might be usefull when you rotate multiple matrices by the same angle
	 * @param	cos	The cosine value for rotation angle
	 * @param	sin	The sine value for rotation angle
	 * @return	this transformed matrix
	 */
	public inline function rotateWithTrig(cos:Float, sin:Float):FlxMatrix
	{
		var a1:Float = a * cos - b * sin;
		b = a * sin + b * cos;
		a = a1;
		
		var c1:Float = c * cos - d * sin;
		d = c * sin + d * cos;
		c = c1;
		
		return this;
	}
	
	/**
	 * Adds 90 degrees to rotation of this matrix
	 * @return	rotated matrix
	 */
	public inline function rotateByPositive90():FlxMatrix
	{
		return this.set(-b, a, -d, c);
	}
	
	/**
	 * Substract 90 degrees from rotation of this matrix
	 * @return	rotated matrix
	 */
	public inline function rotateByNegative90():FlxMatrix
	{
		return this.set(b, -a, d, -c);
	}
	
	/**
	 * Applies scale to this matrix
	 * @param	sx	Scale by x axis
	 * @param	sy	Scale by y axis
	 * @return	Scaled matrix
	 */
	public inline function scale(sx:Float = 1, sy:Float = 1):FlxMatrix
	{
		a *= sx;
		b *= sy;
		
		c *= sx;
		d *= sy;
		
		return this;
	}
	
	/**
	 * Merges this tranformation matrix with specified.
	 */
	public inline function concat(m:FlxMatrix):FlxMatrix
	{
		var a1:Float = a * m.a + b * m.c;
		b = a * m.b + b * m.d;
		a = a1;
		
		var c1:Float = c * m.a + d * m.c;
		d = c * m.b + d * m.d;
		c = c1;
		
		return this;
	}
	
	/**
	 * Removes all transformations from this matrix
	 * @return	identity matrix
	 */
	public inline function identity():FlxMatrix
	{
		a = d = 1;
		b = c = 0;
		return this;
	}
}