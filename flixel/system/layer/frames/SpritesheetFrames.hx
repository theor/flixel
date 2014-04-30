package flixel.system.layer.frames;

import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.system.layer.frames.FlxFrame;
import flixel.system.layer.frames.FlxSpriteFrames;
import flixel.system.layer.frames.FrameCollectionType;
import flixel.system.layer.TileSheetExt;
import flixel.util.loaders.CachedGraphics;

/**
 * ...
 * @author Zaphod
 */
class SpritesheetFrames extends FlxSpriteFrames
{
	public static var POINT1:Point = new Point();
	public static var POINT2:Point = new Point();
	
	public static var RECT:Rectangle = new Rectangle();
	
	private var atlasFrame:FlxFrame;
	private var region:Rectangle;
	private var frameSize:Point;
	private var frameOrigin:Point;
	private var frameSpacing:Point;
	
	private function new(tilesheet:TileSheetExt) 
	{
		super(tilesheet);
		type = FrameCollectionType.SPRITESHEET;
	}
	
	// TODO: implement these methods and think about their signatures (i doubt about first param)
	public static function fromFrame(frame:FlxFrame, frameSize:Point, frameOrigin:Point = null, frameSpacing:Point = null):SpritesheetFrames
	{
		var tilesheet:TileSheetExt = frame.tileSheet;
		var cached:CachedGraphics = tilesheet.cachedGraphics;
		
		// find SpritesheetFrames object, if there is one already
		var spritesheetFrames:SpritesheetFrames = null;
		
		for (sheet in cached.spritesheetFrames)
		{
			if (sheet.equals(frameSize, null, frame, frameOrigin, frameSpacing))
			{
				return sheet;
			}
		}
		
		// or create it, if there is no such object
		spritesheetFrames = new SpritesheetFrames(tilesheet);
		
		var rotated:Bool = (frame.type == FrameType.ROTATED);
		
		// TODO: continue from here...
		
		
		cached.spritesheetFrames.push(spritesheetFrames);
		return spritesheetFrames;
	}
	
	// source can be string, class, cachedGraphics, tilesheetExt or bitmapdata
	public static function fromRectangle(source:Dynamic, frameSize:Point, region:Rectangle = null, frameOrigin:Point = null, frameSpacing:Point = null):SpritesheetFrames
	{
		var cached:CachedGraphics = FlxSpriteFrames.resolveSource(source);
		var tilesheet:TileSheetExt = cached.tilesheet;
		
		// find SpritesheetFrames object, if there is one already
		var spritesheetFrames:SpritesheetFrames = null;
		
		for (sheet in cached.spritesheetFrames)
		{
			if (sheet.equals(frameSize, region, null, frameOrigin, frameSpacing))
			{
				return sheet;
			}
		}
		
		// or create it, if there is no such object
		spritesheetFrames = new SpritesheetFrames(tilesheet);
		
		if (region == null)
		{
			region = cached.bitmap.rect;
		}
		
		if (frameSpacing == null)
		{
			frameSpacing = new Point();
		}
		
		spritesheetFrames.region = region;
		spritesheetFrames.atlasFrame = null;
		spritesheetFrames.frameSize = frameSize;
		spritesheetFrames.frameSpacing = frameSpacing;
		
		var bitmapWidth:Int = Std.int(region.width);
		var bitmapHeight:Int = Std.int(region.height);
		
		var startX:Int = Std.int(region.x);
		var startY:Int = Std.int(region.y);
		
		var endX:Int = startX + bitmapWidth;
		var endY:Int = startY + bitmapHeight;
		
		var xSpacing:Int = Std.int(frameSpacing.x);
		var ySpacing:Int = Std.int(frameSpacing.y);
		
		var width:Int = Std.int(frameSize.x);
		var height:Int = Std.int(frameSize.y);
		
		if (frameOrigin == null)
		{
			frameOrigin = new Point(0.5 * width, 0.5 * height);
		}
		
		spritesheetFrames.frameOrigin = frameOrigin;
		
		var numRows:Int = 1;
		if (height != 0)
		{
			numRows = Std.int((bitmapHeight + ySpacing) / (height + ySpacing));
		}
		
		var numCols:Int = 1;
		if (width != 0)
		{
			numCols = Std.int((bitmapWidth + xSpacing) / (width + xSpacing));
		}
		
		var tempRect:Rectangle;
		
		var spacedWidth:Int = width + xSpacing;
		var spacedHeight:Int = height + ySpacing;
		
		for (j in 0...(numRows))
		{
			for (i in 0...(numCols))
			{
				tempRect = new Rectangle(startX + i * spacedWidth, startY + j * spacedHeight, width, height);
				spritesheetFrames.addSpriteSheetFrame(tempRect, frameOrigin);
			}
		}
		
		cached.spritesheetFrames.push(spritesheetFrames);
		return spritesheetFrames;
	}
	
	public function equals(frameSize:Point, region:Rectangle = null, atlasFrame:FlxFrame = null, frameOrigin:Point = null, frameSpacing:Point = null):Bool
	{
		if (atlasFrame != null)
		{
			region = atlasFrame.frame;
		}
		
		if (region == null)
		{
			region = RECT;
			RECT.x = RECT.y = 0;
			RECT.width = tilesheet.width;
			RECT.height = tilesheet.height;
		}
		
		if (frameOrigin == null)
		{
			frameOrigin = POINT1;
			POINT1.x = 0.5 * frameSize.x;
			POINT1.y = 0.5 * frameSize.y;
		}
		
		if (frameSpacing == null)
		{
			frameSpacing = POINT2;
			POINT2.x = POINT2.y = 0;
		}
		
		return (this.atlasFrame == atlasFrame && this.region.equals(region) && this.frameSize.equals(frameSize) && this.frameSpacing.equals(frameSpacing));
	}
	
	override public function destroy():Void 
	{
		super.destroy();
		
		atlasFrame = null;
		region = null;
		frameSize = null;
		frameOrigin = null;
		frameSpacing = null;
	}
}