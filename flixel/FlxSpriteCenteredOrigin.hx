package flixel;

import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.animation.FlxAnimationController;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.system.FlxAssets;
import flixel.system.layer.DrawStackItem;
import flixel.system.layer.frames.FlxFrame;
import flixel.system.layer.frames.FlxFramesCollection;
import flixel.system.layer.Region;
import flixel.util.FlxAngle;
import flixel.util.FlxColor;
import flixel.util.FlxColorUtil;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxPoint;
import flixel.util.loaders.TexturePackerData;
import flixel.util.loaders.TextureRegion;
import openfl.display.Tilesheet;

@:bitmap("assets/images/logo/default.png")	private class GraphicDefault extends BitmapData {}

/**
 * The main "game object" class, the sprite is a FlxObject
 * with a bunch of graphics options and abilities, like animation and stamping.
 */
class FlxSpriteCenteredOrigin extends FlxSprite
{
	/**
	 * Called by game loop, updates then blits or renders current frame of animation to the screen
	 */
	override public function draw():Void
	{
		if (alpha == 0)	
		{
			return;
		}
		
		if (dirty)	//rarely 
		{
			calcFrame();
		}
		
	#if FLX_RENDER_TILE
		var drawItem:DrawStackItem;
		var currDrawData:Array<Float>;
		var currIndex:Int;
		
		var cos:Float;
		var sin:Float;
	#end
		
		var simpleRender:Bool = isSimpleRender();
		
		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists || !isOnScreen(camera))
			{
				continue;
			}
			
		#if FLX_RENDER_TILE
			drawItem = camera.getDrawStackItem(graphics, isColored, _blendInt, antialiasing);
			currDrawData = drawItem.drawData;
			currIndex = drawItem.position;
			
			_point.x = x - (camera.scroll.x * scrollFactor.x) - (offset.x);
			_point.y = y - (camera.scroll.y * scrollFactor.y) - (offset.y);
			
			_point.x = (_point.x) + origin.x;
			_point.y = (_point.y) + origin.y;
		#else
			_point.x = x - (camera.scroll.x * scrollFactor.x) - (offset.x);
			_point.y = y - (camera.scroll.y * scrollFactor.y) - (offset.y);
		#end
			
#if FLX_RENDER_BLIT
			if (simpleRender)
			{
				_flashPoint.x -= origin.x;
				_flashPoint.y -= origin.y;
				
				// use fround() to deal with floating point precision issues in flash
				_flashPoint.x = Math.fround(_point.x);
				_flashPoint.y = Math.fround(_point.y);
				
				camera.buffer.copyPixels(framePixels, _flashRect, _flashPoint, null, null, true);
			}
			else
			{
				_matrix.identity();
				_matrix.translate( -origin.x, -origin.y);
				_matrix.scale(scale.x, scale.y);
				
				if ((angle != 0) && (bakedRotationAngle <= 0))
				{
					_matrix.rotate(angle * FlxAngle.TO_RAD);
				}
				// see this
			//	_point.x += origin.x;
			//	_point.y += origin.y;
				
				if (pixelPerfectRender)
				{
					_point.floor();
				}
				
				_matrix.translate(_point.x, _point.y);
				camera.buffer.draw(framePixels, _matrix, null, blend, null, (antialiasing || camera.antialiasing));
			}
#else
			var csx:Float = _facingMult;
			var ssy:Float = 0;
			var ssx:Float = 0;
			var csy:Float = 1;
			
			var x1:Float = (origin.x - frame.center.x);
			var y1:Float = (origin.y - frame.center.y);
			
			var x2:Float = x1;
			var y2:Float = y1;
			
			// transformation matrix coefficients
			var a:Float = csx;
			var b:Float = ssx;
			var c:Float = ssy;
			var d:Float = csy;
			
			if (!simpleRender)
			{
				if (_angleChanged && (bakedRotationAngle <= 0))
				{
					var radians:Float = -angle * FlxAngle.TO_RAD;
					_sinAngle = Math.sin(radians);
					_cosAngle = Math.cos(radians);
					_angleChanged = false;
				}
				
				var sx:Float = scale.x * _facingMult;
				
				if (frame.rotated) // todo: handle different additional angles (since different packers adds different values -90 or +90)
				{
					cos = -_sinAngle;
					sin = _cosAngle;
					
					csx = cos * sx;
					ssy = sin * scale.y;
					ssx = sin * sx;
					csy = cos * scale.y;
					
					x2 = x1 * ssx - y1 * csy;
					y2 = x1 * csx + y1 * ssy;
					
					a = csy;
					b = ssy;
					c = ssx;
					d = csx;
				}
				else
				{
					cos = _cosAngle;
					sin = _sinAngle;
					
					csx = cos * sx;
					ssy = sin * scale.y;
					ssx = sin * sx;
					csy = cos * scale.y;
					
					x2 = x1 * csx + y1 * ssy;
					y2 = -x1 * ssx + y1 * csy;
					
					a = csx;
					b = ssx;
					c = ssy;
					d = csy;
				}
			}
			else
			{
				x2 = x1 * csx;
			}
			
			_point.x -= x2;
			_point.y -= y2;
			
			if (pixelPerfectRender)
			{
				_point.floor();
			}
			
			currDrawData[currIndex++] = _point.x;
			currDrawData[currIndex++] = _point.y;
			
			currDrawData[currIndex++] = frame.tileID;
			
			currDrawData[currIndex++] = a;
			currDrawData[currIndex++] = -b;
			currDrawData[currIndex++] = c;
			currDrawData[currIndex++] = d;
			
			if (isColored)
			{
				currDrawData[currIndex++] = _red; 
				currDrawData[currIndex++] = _green;
				currDrawData[currIndex++] = _blue;
			}
			currDrawData[currIndex++] = (alpha * camera.alpha);
			drawItem.position = currIndex;
#end
			#if !FLX_NO_DEBUG
			FlxBasic._VISIBLECOUNT++;
			#end
		}
	}
}
