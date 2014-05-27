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
	public var framesHash:Map<String, FlxFrame>;
	public var parent:CachedGraphics;
	
	public var type(default, null):FrameCollectionType;
	
	public function new(parent:CachedGraphics)
	{
		this.parent = parent;
		frames = [];
		framesHash = new Map<String, FlxFrame>();
		type = FrameCollectionType.USER;
	}
	
	public function destroy():Void
	{
		frames = null;
		framesHash = null;
		parent = null;
		type = null;
	}
	
	// todo: add tiles only with centered origin 
	// (this will require to change some of the rendering methods)
	
	// todo: add empty frame
	public function addEmptyFrame(size:Rectangle):FlxFrame
	{
		var frame:FlxFrame = new FlxFrame(parent);	
		frame.frame = size;
		frame.sourceSize.set(size.width, size.height);
		frames.push(frame);
		return frame;
	}
	
	/**
	 * Adds new FlxFrame to this TileSheetData object
	 */
	public function addSpriteSheetFrame(region:Rectangle):FlxFrame
	{
		var frame:FlxFrame = new FlxFrame(parent);	
		#if FLX_RENDER_TILE
		frame.tileID = parent.tilesheet.addTileRect(region, new Point(0.5 * region.width, 0.5 * region.height));
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
	public function addAtlasFrame(frame:Rectangle, sourceSize:FlxPoint, offset:FlxPoint, name:String = null, angle:Float = 0):FlxFrame
	{
		var texFrame:FlxFrame = null;
		if (angle != 0)
		{
			texFrame = new FlxRotatedFrame(parent);
		}
		else
		{
			texFrame = new FlxFrame(parent);
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
	
	// TODO: move this method to CachedGraphics class
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
		else if (Std.is(Source, BitmapData) || Std.is(Source, String) || Std.is(Source, Class))
		{
			return FlxG.bitmap.add(Source);
		}
		
		return null;
	}
}