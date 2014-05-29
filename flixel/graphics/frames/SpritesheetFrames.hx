package flixel.graphics.frames;

import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FrameCollectionType;
import flixel.system.layer.TileSheetExt;
import flixel.util.FlxBitmapUtil;
import flixel.util.FlxPoint;
import flixel.graphics.FlxGraphics;

/**
 * Spritesheet frame collection. It is used for tilemaps and animated sprites. 
 */
class SpritesheetFrames extends FlxFramesCollection
{
	public static var POINT1:Point = new Point();
	public static var POINT2:Point = new Point();
	
	public static var RECT:Rectangle = new Rectangle();
	
	/**
	 * Atlas frame from which this frame collection had been generated.
	 * Could be null if this collection generated from rectangle.
	 */
	private var atlasFrame:FlxFrame;
	/**
	 * image region of image from which this frame collection had been generated.
	 */
	private var region:Rectangle;
	/**
	 * The size of frame in this spritesheet
	 */
	private var frameSize:Point;
	/**
	 * offsets between frames in this spritesheet
	 */
	private var frameSpacing:Point;
	
	private function new(parent:FlxGraphics) 
	{
		super(parent);
		type = FrameCollectionType.SPRITESHEET;
	}
	
	/**
	 * Gets source bitmapdata, generates new bitmapdata with spaces between frames (if there is no such bitmapdata in the cache already) 
	 * and creates SpritesheetFrames collection
	 * @param	source			the source of graphics for frame collection 
	 * 							(can be String, Class<Dynamic>, BitmapData, FlxGraphics, FlxFrame or FlxFramesCollection)
	 * @param	frameSize		the size of tiles in spritesheet
	 * @param	frameSpacing	desired offsets between frames in spritesheet
	 * 							(this method takes spritesheet bitmap without offsets between frames and adds them).
	 * @param	region			Region of image to generate spritesheet from. Default value is null, which means that
	 * 							whole image will be used for spritesheet generation
	 * @return	Newly created spritesheet
	 */
	public static function fromBitmapWithSpacings(source:Dynamic, frameSize:Point, frameSpacing:Point, region:Rectangle = null):SpritesheetFrames
	{
		var graphics:FlxGraphics = FlxGraphics.resolveSource(source);
		
		if (graphics == null) return null;
		
		var key:String = FlxG.bitmap.getKeyWithSpacings(graphics.key, frameSize, frameSpacing, region);
		
		var result:FlxGraphics = FlxG.bitmap.get(key);
		if (result == null)
		{
			var bitmap:BitmapData = FlxBitmapUtil.addSpacing(graphics.bitmap, frameSize, frameSpacing, region);
			result = FlxG.bitmap.add(bitmap, false, key);
		}
		
		return SpritesheetFrames.fromRectangle(result, frameSize, null, frameSpacing);
	}
	
	/**
	 * Generates spritesheet frame collection from provided frame. Can be usefull for spritesheets packed into atlases.
	 * It can generate spritesheets from rotated and cropped frames also, which is important for devices with small amount of memory.
	 * @param	frame			frame, containg spritesheet image
	 * @param	frameSize		the size of tiles in spritesheet
	 * @param	frameSpacing	offsets between frames in spritesheet. Default value is null, which means no offsets between tiles
	 * @return	Newly created spritesheet frame collection.
	 */
	public static function fromFrame(frame:FlxFrame, frameSize:Point, frameSpacing:Point = null):SpritesheetFrames
	{
		var graphics:FlxGraphics = frame.parent;
		
		// find SpritesheetFrames object, if there is one already
		var spritesheetFrames:SpritesheetFrames = null;
		
		for (sheet in graphics.spritesheetFrames)
		{
			if (sheet.equals(frameSize, null, frame, frameSpacing))
			{
				return sheet;
			}
		}
		
		// or create it, if there is no such object
		spritesheetFrames = new SpritesheetFrames(graphics);
		
		if (frameSpacing == null)
		{
			frameSpacing = new Point();
		}
		
		spritesheetFrames.atlasFrame = frame;
		spritesheetFrames.region = frame.frame;
		spritesheetFrames.frameSize = frameSize;
		spritesheetFrames.frameSpacing = frameSpacing;
		
		var bitmapWidth:Int = Std.int(frame.sourceSize.x);
		var bitmapHeight:Int = Std.int(frame.sourceSize.y);
		
		var xSpacing:Int = Std.int(frameSpacing.x);
		var ySpacing:Int = Std.int(frameSpacing.y);
		
		var frameWidth:Int = Std.int(frameSize.x);
		var frameHeight:Int = Std.int(frameSize.y);
		
		var spacedWidth:Int = frameWidth + xSpacing;
		var spacedHeight:Int = frameHeight + ySpacing;
		
		var numRows:Int = 1;
		if (frameHeight != 0)
		{
			numRows = Std.int((bitmapHeight + ySpacing) / spacedHeight);
		}
		
		var numCols:Int = 1;
		if (frameWidth != 0)
		{
			numCols = Std.int((bitmapWidth + xSpacing) / spacedWidth);
		}
		
		var clippedRect:Rectangle = new Rectangle(frame.offset.x, frame.offset.y, frame.frame.width, frame.frame.height);
		
		var frameRect:Rectangle;
		
		var helperRect:Rectangle = new Rectangle(0, 0, frameWidth, frameHeight);
		
		var frameOffset:FlxPoint;
		
		var frameX:Int = 0;
		var frameY:Int = 0;
		
		var rotated:Bool = (frame.type == FrameType.ROTATED);
		var angle:Float = 0;
		
		var startX:Int = 0;
		var startY:Int = 0;
		var dX:Int = spacedWidth;
		var dY:Int = spacedHeight;
		
		if (rotated)
		{
			var rotatedFrame:FlxRotatedFrame = cast frame;
			
			angle = rotatedFrame.additionalAngle;
			
			if (angle == -90)
			{
				startX = Std.int(frame.sourceSize.x);
				startY = 0;
				dX = -spacedHeight;
				dY = spacedWidth;
				clippedRect.x = frame.sourceSize.y - frame.offset.y - frame.frame.width;
				clippedRect.y = frame.offset.x;
			}
			else if (angle == 90)
			{
				startX = 0;
				startY = Std.int(frame.sourceSize.y);
				dX = spacedHeight;
				dY = -spacedWidth;
				clippedRect.x = frame.offset.y;
				clippedRect.y = frame.sourceSize.x - frame.offset.x - frame.frame.height;
			}
			
			helperRect.width = frameHeight;
			helperRect.height = frameWidth;
		}
		
		for (j in 0...(numRows))
		{
			for (i in 0...(numCols))
			{
				helperRect.x = frameX = startX + dX * i;
				helperRect.y = frameY = startY + dY * j;
				
				frameRect = clippedRect.intersection(helperRect);
				
				if (frameRect.width == 0 || frameRect.height == 0)
				{
					frameRect.x = frameRect.y = 0;
					frameRect.width = frameWidth;
					frameRect.height = frameHeight;
					
					spritesheetFrames.addEmptyFrame(frameRect);
				}
				else
				{
					frameOffset = FlxPoint.get(frameRect.x - frameX, frameRect.y - frameY);
					
					frameRect.x += frame.frame.x;
					frameRect.y += frame.frame.y;
					
					spritesheetFrames.addAtlasFrame(frameRect, FlxPoint.get(frameWidth, frameHeight), frameOffset, null, angle);
				}
			}
		}
		
		graphics.spritesheetFrames.push(spritesheetFrames);
		return spritesheetFrames;
	}
	
	// TODO: use FlxPoint and FlxRect as method arguments
	
	/**
	 * Generates spritesheet frame collection from provided region of image.
	 * @param	source			source graphics for spritesheet.
	 * 							It can be BitmapData, Class<Dynamic>, String, FlxGraphics, FlxFrame or FlxFramesCollection
	 * @param	frameSize		the size of tiles in spritesheet
	 * @param	region			region of image to use for spritesheet generation. Default value is null,
	 * 							which means that whole image will be used for it.
	 * @param	frameSpacing	offsets between frames in spritesheet. Default value is null, which means no offsets between tiles
	 * @return	Newly created spritesheet frame collection
	 */
	public static function fromRectangle(source:Dynamic, frameSize:Point, region:Rectangle = null, frameSpacing:Point = null):SpritesheetFrames
	{
		var graphics:FlxGraphics = FlxGraphics.resolveSource(source);
		
		// find SpritesheetFrames object, if there is one already
		var spritesheetFrames:SpritesheetFrames = null;
		
		for (sheet in graphics.spritesheetFrames)
		{
			if (sheet.equals(frameSize, region, null, frameSpacing))
			{
				return sheet;
			}
		}
		
		// or create it, if there is no such object
		spritesheetFrames = new SpritesheetFrames(graphics);
		
		if (region == null)
		{
			region = graphics.bitmap.rect;
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
		
		var xSpacing:Int = Std.int(frameSpacing.x);
		var ySpacing:Int = Std.int(frameSpacing.y);
		
		var width:Int = Std.int(frameSize.x);
		var height:Int = Std.int(frameSize.y);
		
		var spacedWidth:Int = width + xSpacing;
		var spacedHeight:Int = height + ySpacing;
		
		var numRows:Int = 1;
		if (height != 0)
		{
			numRows = Std.int((bitmapHeight + ySpacing) / spacedHeight);
		}
		
		var numCols:Int = 1;
		if (width != 0)
		{
			numCols = Std.int((bitmapWidth + xSpacing) / spacedWidth);
		}
		
		var tempRect:Rectangle;
		
		for (j in 0...(numRows))
		{
			for (i in 0...(numCols))
			{
				tempRect = new Rectangle(startX + i * spacedWidth, startY + j * spacedHeight, width, height);
				spritesheetFrames.addSpriteSheetFrame(tempRect);
			}
		}
		
		graphics.spritesheetFrames.push(spritesheetFrames);
		return spritesheetFrames;
	}
	
	/**
	 * SpritesheetFrames comparison method. For internal use.
	 */
	public function equals(frameSize:Point, region:Rectangle = null, atlasFrame:FlxFrame = null, frameSpacing:Point = null):Bool
	{
		if (atlasFrame != null)
		{
			region = atlasFrame.frame;
		}
		
		if (region == null)
		{
			region = RECT;
			RECT.x = RECT.y = 0;
			RECT.width = parent.width;
			RECT.height = parent.height;
		}
		
		if (frameSpacing == null)
		{
			frameSpacing = POINT1;
			POINT1.x = POINT1.y = 0;
		}
		
		return (this.atlasFrame == atlasFrame && this.region.equals(region) && this.frameSize.equals(frameSize) && this.frameSpacing.equals(frameSpacing));
	}
	
	override public function destroy():Void 
	{
		super.destroy();
		
		atlasFrame = null;
		region = null;
		frameSize = null;
		frameSpacing = null;
	}
}