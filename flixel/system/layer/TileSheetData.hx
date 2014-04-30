package flixel.system.layer;

import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.interfaces.IFlxDestroyable;
import flixel.system.layer.frames.FlxFrame;
import flixel.system.layer.frames.FlxRotatedFrame;
import flixel.system.layer.frames.FlxSpriteFrames;
import flixel.system.layer.Region;
import flixel.system.layer.TileSheetExt;
import flixel.util.FlxPoint;
import flixel.util.loaders.TextureAtlasFrame;
import flixel.util.loaders.TexturePackerData;

/**
 * Object of this class holds information about single Tilesheet
 */
class TileSheetData implements IFlxDestroyable
{
	#if FLX_RENDER_TILE
	public var tileSheet:TileSheetExt;
	#end
	
	/**
	 * Storage for all groups of FlxFrames.
	 * WARNING: accessing Map data structure causes string allocations - avoid doing every frame.
	 */
	private var flxSpriteFrames:Map<String, FlxSpriteFrames>;
	
	/**
	 * Storage for all FlxFrames in this TileSheetData object.
	 * WARNING: accessing Map data structure causes string allocations - avoid doing every frame.
	 */
	private var flxFrames:Map<String, FlxFrame>;
	
	private var frameNames:Array<String>;
	
	private var framesArr:Array<FlxFrame>;
	
	public var bitmap:BitmapData;
	
	public function new(Bitmap:BitmapData)
	{
		bitmap = Bitmap;
		#if FLX_RENDER_TILE
		tileSheet = new TileSheetExt(bitmap);
		#end
		flxSpriteFrames = new Map<String, FlxSpriteFrames>();
		flxFrames = new Map<String, FlxFrame>();
		frameNames = new Array<String>();
		framesArr = new Array<FlxFrame>();
	}
	
	public inline function getFrame(name:String):FlxFrame
	{
		return flxFrames.get(name);
	}
	
	public function getSpriteSheetFrames(region:Region, ?origin:Point):FlxSpriteFrames
	{
		var bitmapWidth:Int = region.width;
		var bitmapHeight:Int = region.height;
		
		var startX:Int = region.startX;
		var startY:Int = region.startY;
		
		var endX:Int = startX + bitmapWidth;
		var endY:Int = startY + bitmapHeight;
		
		var xSpacing:Int = region.spacingX;
		var ySpacing:Int = region.spacingY;
		
		var width:Int = (region.tileWidth == 0) ? bitmapWidth : region.tileWidth;
		var height:Int = (region.tileHeight == 0) ? bitmapHeight : region.tileHeight;
		
		var pointX:Float = 0.5 * width;
		var pointY:Float = 0.5 * height;
		
		if (origin != null)
		{
			pointX = origin.x;
			pointY = origin.y;
		}
		
		var key:String = getKeyForSpriteSheetFrames(width, height, startX, startY, endX, endY, xSpacing, ySpacing, pointX, pointY);
		if (flxSpriteFrames.exists(key))
		{
			return flxSpriteFrames.get(key);
		}
		
		var numRows:Int = region.numRows;
		var numCols:Int = region.numCols;
		
		var tempPoint:Point = origin;
		if (origin == null)
		{
			tempPoint = new Point(pointX, pointY);
		}
		
		var spriteData:FlxSpriteFrames = new FlxSpriteFrames(key);
		
		var frame:FlxFrame;
		var tempRect:Rectangle;
		
		var spacedWidth:Int = width + xSpacing;
		var spacedHeight:Int = height + ySpacing;
		
		for (j in 0...(numRows))
		{
			for (i in 0...(numCols))
			{
				tempRect = new Rectangle(startX + i * spacedWidth, startY + j * spacedHeight, width, height);
				frame = addSpriteSheetFrame(tempRect, tempPoint);
				spriteData.addFrame(frame);
			}
		}
		
		flxSpriteFrames.set(key, spriteData);
		return spriteData;
	}
	
	public inline function containsFrame(key:String):Bool
	{
		return flxFrames.exists(key);
	}
	
	public function destroy():Void
	{
		bitmap = null;
		#if FLX_RENDER_TILE
		tileSheet.destroy();
		tileSheet = null;
		#end
		
		for (frames in flxSpriteFrames)
		{
			frames.destroy();
		}
		flxSpriteFrames = null;
		
		for (frame in framesArr)
		{
			frame.destroy();
		}
		flxFrames = null;
		
		frameNames = null;
		framesArr = null;
	}
	
	#if FLX_RENDER_TILE
	public function onContext(bitmap:BitmapData):Void
	{
		this.bitmap = bitmap;
		var newSheet:TileSheetExt = new TileSheetExt(bitmap);
		newSheet.rebuildFromOld(tileSheet);
		tileSheet = newSheet;
	}
	#end
	
	public function destroyBitmaps():Void
	{
		var numFrames:Int = frameNames.length;
		for (frame in framesArr)
		{
			frame.destroyBitmaps();
		}
	}
}