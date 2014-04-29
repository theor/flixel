package flixel.system.layer.frames;

import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.interfaces.IFlxDestroyable;
import flixel.system.layer.TileSheetExt;
import flixel.util.FlxPoint;
import flixel.util.loaders.CachedGraphics;

class FlxSpriteFrames implements IFlxDestroyable
{
	public var frames:Array<FlxFrame>;
	public var tilesheet:TileSheetExt;
	
	public var type(default, null):FrameCollectionType;
	
	public function new(tilesheet:TileSheetExt)
	{
		this.tilesheet = tilesheet;
		frames = [];
		type = FrameCollectionType.USER;
	}
	
	public function destroy():Void
	{
		frames = null;
		tilesheet = null;
		type = null;
	}
	
	/**
	 * Adds new FlxFrame to this TileSheetData object
	 */
	public function addSpriteSheetFrame(region:Rectangle, origin:Point = null):FlxFrame
	{
		var frame:FlxFrame = new FlxFrame(tilesheet);	
		#if FLX_RENDER_TILE
		if (origin == null)
		{
			origin = new Point(0.5 * region.width, 0.5 * region.height);
		}
		
		frame.tileID = tilesheet.addTileRect(region, origin);
		#end
		frame.frame = region;
		frame.sourceSize.set(region.width, region.height);
		frame.offset.set(0, 0);
		frame.center.set(0.5 * region.width, 0.5 * region.height);
		frames.push(frame);
		return frame;
	}
	
	/**
	 * Parses frame TexturePacker data object and returns it
	 */
	private function addAtlasFrame(frame:Rectangle, sourceSize:FlxPoint, offset:FlxPoint, name:String = null, angle:Float = 0):FlxFrame
	{
		var texFrame:FlxFrame = null;
		if (angle != 0)
		{
			texFrame = new FlxRotatedFrame(tilesheet);
		}
		else
		{
			texFrame = new FlxFrame(tilesheet);
		}
		
		texFrame.name = name;
		texFrame.sourceSize.set(sourceSize.x, sourceSize.y);
		texFrame.offset.set(offset.x, offset.y);	
		texFrame.frame = frame;
		texFrame.additionalAngle = angle;
		
		sourceSize.put();
		offset.put();
		
		if (angle != 0)
		{
			texFrame.center.set(texFrame.frame.height * 0.5 + texFrame.offset.x, texFrame.frame.width * 0.5 + texFrame.offset.y);
		}
		else
		{
			texFrame.center.set(texFrame.frame.width * 0.5 + texFrame.offset.x, texFrame.frame.height * 0.5 + texFrame.offset.y);
		}
		
		#if FLX_RENDER_TILE
		texFrame.tileID = tilesheet.addTileRect(texFrame.frame, new Point(0.5 * texFrame.frame.width, 0.5 * texFrame.frame.height));
		#end
		
		frames.push(texFrame);
		return texFrame;
	}
	
	public static function resolveSource(Source:Dynamic):CachedGraphics
	{
		if (Source == null)
		{
			return null;
		}
		
		if (Std.is(Source, CachedGraphics))
		{
			return cast Source;
		}
		else if (Std.is(Source, TileSheetExt))
		{
			return cast(Source, TileSheetExt).cachedGraphics;
		}
		else if (Std.is(Source, BitmapData) || Std.is(Source, String))
		{
			return FlxG.bitmap.add(Source);
		}
		
		return null;
	}
}