package flixel.system.layer.frames;

import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.system.layer.TileSheetExt;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxPoint;
import flixel.util.loaders.CachedGraphics;

class ImageFrame extends FlxSpriteFrames
{
	public static var POINT:Point = new Point();
	public static var RECT:Rectangle = new Rectangle();
	
	public var frame:FlxFrame;
	public var origin:Point;
	
	private function new(tilesheet:TileSheetExt) 
	{
		super(tilesheet);
		type = FrameCollectionType.IMAGE;
	}
	
	public static function fromImage(source:Dynamic, origin:Point = null):ImageFrame
	{
		return fromRectangle(source, null, origin);
	}
	
	public static function fromRectangle(source:Dynamic, region:Rectangle = null, origin:Point = null):ImageFrame
	{
		var cached:CachedGraphics = FlxSpriteFrames.resolveSource(source);
		var tilesheet:TileSheetExt = cached.tilesheet;
		// find ImageFrame, if there is one already
		var imageFrame:ImageFrame = null;
		
		var checkRegion:Rectangle = region;
		var checkOrigin:Point = origin;
		
		if (checkRegion == null)
		{
			checkRegion = RECT;
			checkRegion.x = checkRegion.y = 0;
			checkRegion.width = tilesheet.width;
			checkRegion.height = tilesheet.height;
		}
		
		if (checkOrigin == null)
		{
			checkOrigin = POINT;
			checkOrigin.x = 0.5 * region.width;
			checkOrigin.y = 0.5 * region.height;
		}
		
		for (imageFrame in cached.imageFrames)
		{
			if (imageFrame.equals(checkRegion, checkOrigin))
			{
				return imageFrame;
			}
		}
		
		// or create it, if there is no such object
		imageFrame = new ImageFrame(tilesheet);
		
		if (region == null)
		{
			region = new Rectangle(0, 0, tilesheet.width, tilesheet.height);
		}
		
		if (origin == null)
		{
			origin = new Point(0.5 * region.width, 0.5 * region.height);
		}
		
		imageFrame.frame = imageFrame.addSpriteSheetFrame(region, origin);
		imageFrame.origin = origin;
		
		cached.imageFrames.push(imageFrame);
		return imageFrame;
	}
	
	public function equals(rect:Rectangle = null, origin:Point = null):Bool
	{
		return (rect.equals(frame.frame) && origin.equals(this.origin));
	}
	
	override public function destroy():Void 
	{
		super.destroy();
		frame = FlxDestroyUtil.destroy(frame);
		origin = null;
	}
}