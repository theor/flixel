package flixel.graphics.frames;

import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.system.layer.TileSheetExt;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxPoint;
import flixel.graphics.FlxGraphic;

/**
 * Single-frame collection.
 * Could be useful for non-animated sprites
 */
class ImageFrame extends FlxFramesCollection
{
	public static var POINT:Point = new Point();
	public static var RECT:Rectangle = new Rectangle();
	
	/**
	 * Single frame of this frame collection.
	 * Added this var for faster access, so you don't need to type something like: imageFrame.frames[0]
	 */
	public var frame:FlxFrame;
	
	private function new(parent:FlxGraphic) 
	{
		super(parent);
		type = FrameCollectionType.IMAGE;
	}
	
	/**
	 * Generates ImageFrame object for specified FlxFrame
	 * @param	source	FlxFrame to generate ImageFrame from
	 * @return	Created ImageFrame object
	 */
	public static function fromFrame(source:FlxFrame):ImageFrame
	{
		var graphic:FlxGraphic = source.parent;
		var rect:Rectangle = source.frame;
		
		for (imageFrame in graphic.imageFrames)
		{
			if (imageFrame.equals(rect))
			{
				return imageFrame;
			}
		}
		
		var imageFrame:ImageFrame = new ImageFrame(graphic);
		imageFrame.frame = imageFrame.addSpriteSheetFrame(rect.clone());
		graphic.imageFrames.push(imageFrame);
		return imageFrame;
	}
	
	/**
	 * Creates ImageFrame object for the whole image
	 * @param	source	image graphic for ImageFrame. It could be String, BitmapData, Class<Dynamic>, FlxGraphic, FlxFrame or FlxFrameCollection
	 * @return	Newly created ImageFrame object for specified graphic
	 */
	public static function fromImage(source:Dynamic):ImageFrame
	{
		return fromRectangle(source, null);
	}
	
	/**
	 * Creates ImageFrame object for specified region of image
	 * @param	source	image graphic for ImageFrame. It could be String, BitmapData, Class<Dynamic>, FlxGraphic, FlxFrame or FlxFrameCollection
	 * @param	region	region of image to create ImageFrame for
	 * @return	Newly created ImageFrame object for specified region of image
	 */
	public static function fromRectangle(source:Dynamic, region:Rectangle = null):ImageFrame
	{
		var graphic:FlxGraphic = FlxGraphic.resolveSource(source);
		// find ImageFrame, if there is one already
		var imageFrame:ImageFrame = null;
		
		var checkRegion:Rectangle = region;
		
		if (checkRegion == null)
		{
			checkRegion = RECT;
			checkRegion.x = checkRegion.y = 0;
			checkRegion.width = graphic.width;
			checkRegion.height = graphic.height;
		}
		
		for (imageFrame in graphic.imageFrames)
		{
			if (imageFrame.equals(checkRegion))
			{
				return imageFrame;
			}
		}
		
		// or create it, if there is no such object
		imageFrame = new ImageFrame(graphic);
		
		if (region == null)
		{
			region = new Rectangle(0, 0, graphic.width, graphic.height);
		}
		else
		{
			if (region.width == 0)
			{
				region.width = graphic.width - region.x;
			}
			
			if (region.height == 0)
			{
				region.height = graphic.height - region.y;
			}
		}
		
		imageFrame.frame = imageFrame.addSpriteSheetFrame(region);
		
		graphic.imageFrames.push(imageFrame);
		return imageFrame;
	}
	
	/**
	 * ImageFrame comparison method. For internal use.
	 */
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