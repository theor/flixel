package flixel.system.layer.frames;

import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.system.layer.frames.FlxFrame;
import flixel.system.layer.frames.FlxSpriteFrames;
import flixel.system.layer.frames.FrameCollectionType;
import flixel.system.layer.TileSheetExt;

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
	//	var frames:SpritesheetFrames = new SpritesheetFrames(tilesheet);
		
		
		
	//	return frames;
		
		return null;
	}
	
	// source can be string, class, cachedGraphics, tilesheetExt or bitmapdata
	public static function fromRectangle(source:Dynamic, frameSize:Point, region:Rectangle = null, frameOrigin:Point = null, frameSpacing:Point = null):SpritesheetFrames
	{
	//	var frames:SpritesheetFrames = new SpritesheetFrames(tilesheet);
		
		
		
	//	return frames;
		
		return null;
	}
	
	public static function fromFrames(frames:Array<FlxFrame>):SpritesheetFrames
	{
		return null;
	}
	
	private static function getFrames(tilesheet:TileSheetExt, frameSize:Point, region:Rectangle = null, atlasFrame:FlxFrame = null, frameOrigin:Point = null, frameSpacing:Point = null):SpritesheetFrames
	{
		return null;
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