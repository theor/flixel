package flixel.graphics.frames;

import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.system.layer.TileSheetExt;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxPoint;
import flixel.graphics.FlxGraphics;

class ImageFrame extends FlxSpriteFrames
{
	public static var POINT:Point = new Point();
	public static var RECT:Rectangle = new Rectangle();
	
	public var frame:FlxFrame;
	
	private function new(parent:FlxGraphics) 
	{
		super(parent);
		type = FrameCollectionType.IMAGE;
	}
	
	/**
	 * 
	 * @param	source
	 * @return
	 */
	public static function fromFrame(source:FlxFrame):ImageFrame
	{
		var graphics:FlxGraphics = source.parent;
		var rect:Rectangle = source.frame;
		
		for (imageFrame in graphics.imageFrames)
		{
			if (imageFrame.equals(rect))
			{
				return imageFrame;
			}
		}
		
		var imageFrame:ImageFrame = new ImageFrame(graphics);
		imageFrame.frame = imageFrame.addSpriteSheetFrame(rect.clone());
		graphics.imageFrames.push(imageFrame);
		return imageFrame;
	}
	
	public static function fromImage(source:Dynamic):ImageFrame
	{
		return fromRectangle(source, null);
	}
	
	public static function fromRectangle(source:Dynamic, region:Rectangle = null):ImageFrame
	{
		var graphics:FlxGraphics = FlxGraphics.resolveSource(source);
		// find ImageFrame, if there is one already
		var imageFrame:ImageFrame = null;
		
		var checkRegion:Rectangle = region;
		
		if (checkRegion == null)
		{
			checkRegion = RECT;
			checkRegion.x = checkRegion.y = 0;
			checkRegion.width = graphics.width;
			checkRegion.height = graphics.height;
		}
		
		for (imageFrame in graphics.imageFrames)
		{
			if (imageFrame.equals(checkRegion))
			{
				return imageFrame;
			}
		}
		
		// or create it, if there is no such object
		imageFrame = new ImageFrame(graphics);
		
		if (region == null)
		{
			region = new Rectangle(0, 0, graphics.width, graphics.height);
		}
		else
		{
			if (region.width == 0)
			{
				region.width = graphics.width - region.x;
			}
			
			if (region.height == 0)
			{
				region.height = graphics.height - region.y;
			}
		}
		
		imageFrame.frame = imageFrame.addSpriteSheetFrame(region);
		
		graphics.imageFrames.push(imageFrame);
		return imageFrame;
	}
	
	public function equals(rect:Rectangle = null):Bool
	{
		return (rect.equals(frame.frame));
	}
	
	override public function destroy():Void 
	{
		super.destroy();
		frame = FlxDestroyUtil.destroy(frame);
	}
}