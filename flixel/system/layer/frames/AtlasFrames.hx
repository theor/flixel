package flixel.system.layer.frames;
import flixel.util.FlxPoint;
import haxe.xml.Fast;

import flash.display.BitmapData;
import flash.geom.Rectangle;
import flixel.system.layer.frames.FlxFrame;
import flixel.system.layer.frames.FlxSpriteFrames;
import flixel.system.layer.frames.FrameCollectionType;
import flixel.system.layer.TileSheetExt;
import flixel.util.loaders.CachedGraphics;
import haxe.Json;

/**
 * ...
 * @author Zaphod
 */
class AtlasFrames extends FlxSpriteFrames
{
	public var framesHash:Map<String, FlxFrame>;
	
	private function new(tilesheet:TileSheetExt) 
	{
		super(tilesheet);
		type = FrameCollectionType.ATLAS;
		framesHash = new Map<String, FlxFrame>();
	}
	
	override public function destroy():Void
	{
		super.destroy();
		framesHash = null;
	}
	
	override function addAtlasFrame(frame:Rectangle, sourceSize:FlxPoint, offset:FlxPoint, name:String = null, angle:Float = 0):FlxFrame 
	{
		var frame:FlxFrame = super.addAtlasFrame(frame, sourceSize, offset, name, angle);
		
		if (frame.name != null)
		{
			framesHash.set(frame.name, frame);
		}
		
		return frame;
	}
	
	// TODO: implement this and other parsing methods
	
	// Description - contents of JSON file: Assets.getText(description)
	public static function texturePackerJSON(Source:Dynamic, Description:String):AtlasFrames
	{
		var cached:CachedGraphics = FlxSpriteFrames.resolveSource(Source);
		
		// No need to parse data again
		if (cached.atlasFrames != null)
			return cached.atlasFrames;
		
		if ((cached == null) || (Description == null)) return null;
		
		var frames:AtlasFrames = new AtlasFrames(cached.tilesheet);
		var data:Dynamic = Json.parse(Description);
		
		for (frame in Lambda.array(data.frames))
		{
			var rotated:Bool = frame.rotated;
			var name:String = frame.filename;
			var sourceSize:FlxPoint = FlxPoint.get(frame.sourceSize.w, frame.sourceSize.h);
			var offset:FlxPoint = FlxPoint.get(frame.spriteSourceSize.x, frame.spriteSourceSize.y);
			var angle:Float = 0;
			var frameRect:Rectangle = null;
			
			if (rotated)
			{
				frameRect = new Rectangle(frame.frame.x, frame.frame.y, frame.frame.h, frame.frame.w);
				angle = -90;
			}
			else
			{
				frameRect = new Rectangle(frame.frame.x, frame.frame.y, frame.frame.w, frame.frame.h);
			}
			
			frames.addAtlasFrame(frameRect, sourceSize, offset, name, angle);
		}
		
		cached.atlasFrames = frames;
		return frames;
	}
	
	// Description - contents of XML file: Assets.getText(description)
	public static function sparrow(Source:Dynamic, Description:String):AtlasFrames
	{
		var cached:CachedGraphics = FlxSpriteFrames.resolveSource(Source);
		
		// No need to parse data again
		if (cached.atlasFrames != null)
			return cached.atlasFrames;
		
		if ((cached == null) || (Description == null)) return null;
		
		var frames:AtlasFrames = new AtlasFrames(cached.tilesheet);
		
		var data:Fast = new haxe.xml.Fast(Xml.parse(Description).firstElement());
		
		for (texture in data.nodes.SubTexture)
		{
			var angle:Float = 0;
			var name:String = texture.att.name;
			var trimmed:Bool = texture.has.frameX;
			
			//var frameRect:Rectangle = new Rectangle(frame.frame.x, frame.frame.y, frame.frame.w, frame.frame.h);
			
			/*
			var rect:Rectangle = new Rectangle(
				Std.parseFloat(texture.att.x), Std.parseFloat(texture.att.y),
				Std.parseFloat(texture.att.width), Std.parseFloat(texture.att.height));
			
			var size:Rectangle = if (trimmed) // trimmed
					new Rectangle(
						Std.parseInt(texture.att.frameX), Std.parseInt(texture.att.frameY),
						Std.parseInt(texture.att.frameWidth), Std.parseInt(texture.att.frameHeight));
				else 
					new Rectangle(0, 0, rect.width, rect.height);
			
			texFrame.offset = FlxPoint.get(0, 0);
			texFrame.offset.set(-size.left, -size.top);
			
			texFrame.sourceSize = FlxPoint.get(size.width, size.height);	
			texFrame.frame = rect;
			
			frames.push(texFrame);
			*/
		}
		
		cached.atlasFrames = frames;
		return frames;
	}
	
	
}