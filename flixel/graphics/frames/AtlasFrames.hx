package flixel.graphics.frames;

import flixel.util.FlxPoint;
import haxe.xml.Fast;

import flash.display.BitmapData;
import flash.geom.Rectangle;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FrameCollectionType;
import flixel.system.layer.TileSheetExt;
import flixel.graphics.FlxGraphic;
import haxe.Json;

/**
 * Atlas frames collection. It makes possible to use texture atlases in flixel. 
 * Plus it contains few packer parser methods for most commonly used atlas formats.
 */
class AtlasFrames extends FlxFramesCollection
{
	@:allow(flixel.atlas.FlxAtlas)
	private function new(parent:FlxGraphic) 
	{
		super(parent);
		type = FrameCollectionType.ATLAS;
	}
	
	/**
	 * Parsing method for TexturePacker atlases in json format
	 * @param	Source			the image source (can be FlxGraphic, String, Class<Dynamic>, BitmapData, FlxFrame or FlxFramesCollection)
	 * @param	Description		contents of json file with atlas description. You can get it with Assets.getText(path/to/description.json)
	 * @return	Newly created AtlasFrames collection
	 */
	public static function texturePackerJSON(Source:Dynamic, Description:String):AtlasFrames
	{
		var graphics:FlxGraphic = FlxGraphic.resolveSource(Source);
		
		// No need to parse data again
		if (graphics.atlasFrames != null)
			return graphics.atlasFrames;
		
		if ((graphics == null) || (Description == null)) return null;
		
		var frames:AtlasFrames = new AtlasFrames(graphics);
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
		
		graphics.atlasFrames = frames;
		return frames;
	}
	
	/**
	 * Parsing method for LibGDX atlases
	 * @param	Source			the image source (can be FlxGraphic, String, Class<Dynamic>, BitmapData, FlxFrame or FlxFramesCollection)
	 * @param	Description		contents of the file with atlas description. You can get it with Assets.getText(path/to/description/file)
	 * @return	Newly created AtlasFrames collection
	 */
	public static function libGDX(Source:Dynamic, Description:String):AtlasFrames
	{
		var graphics:FlxGraphic = FlxGraphic.resolveSource(Source);
		
		// No need to parse data again
		if (graphics.atlasFrames != null)
			return graphics.atlasFrames;
		
		if ((graphics == null) || (Description == null)) return null;
		
		var frames:AtlasFrames = new AtlasFrames(graphics);
		
		var pack:String = StringTools.trim(Description);
		var lines:Array<String> = pack.split("\n");
		lines.splice(0, 4);
		var numElementsPerImage:Int = 7;
		var numImages:Int = Std.int(lines.length / numElementsPerImage);
		
		var curIndex:Int;
		var imageX:Int;
		var imageY:Int;
		
		var imageWidth:Int;
		var imageHeight:Int;
		
		var size:Array<Int> = [];
		var tempString:String;
		
		for (i in 0...numImages)
		{
			curIndex = i * numElementsPerImage;
			
			var name:String = lines[curIndex++];
			var rotated:Bool = (lines[curIndex++].indexOf("true") >= 0);
			var angle:Float = 0;
			
			tempString = lines[curIndex++];
			size = getDimensions(tempString, size);
			
			imageX = size[0];
			imageY = size[1];
			
			tempString = lines[curIndex++];
			size = getDimensions(tempString, size);
			
			imageWidth = size[0];
			imageHeight = size[1];
			
			var rect:Rectangle = null;
			
			if (rotated)
			{
				rect = new Rectangle(imageX, imageY, imageHeight, imageWidth);
				angle = 90;
			}
			else
			{
				rect = new Rectangle(imageX, imageY, imageWidth, imageHeight);
			}
			
			tempString = lines[curIndex++];
			size = getDimensions(tempString, size);
			
			var sourceSize:FlxPoint = FlxPoint.get(size[0], size[1]);
			
			tempString = lines[curIndex++];
			size = getDimensions(tempString, size);
			
			var offset:FlxPoint = FlxPoint.get(size[0], size[1]);
			frames.addAtlasFrame(rect, sourceSize, offset, name, angle);
		}
		
		graphics.atlasFrames = frames;
		return frames;
	}
	
	/**
	 * Internal method for LibGDX atlas parsing
	 */
	private static function getDimensions(line:String, size:Array<Int>):Array<Int>
	{
		var colonPosition:Int = line.indexOf(":");
		var comaPosition:Int = line.indexOf(",");
		
		size[0] = Std.parseInt(line.substring(colonPosition + 1, comaPosition));
		size[1] = Std.parseInt(line.substring(comaPosition + 1, line.length));
		
		return size;
	}
	
	/**
	 * Parsing method for Sparrow texture atlases
	 * @param	Source			the image source (can be FlxGraphic, String, Class<Dynamic>, BitmapData, FlxFrame or FlxFramesCollection)
	 * @param	Description		contents of xml file with atlas description. You can get it with Assets.getText(path/to/description.xml)
	 * @return	Newly created AtlasFrames collection
	 */
	public static function sparrow(Source:Dynamic, Description:String):AtlasFrames
	{
		var graphics:FlxGraphic = FlxGraphic.resolveSource(Source);
		
		// No need to parse data again
		if (graphics.atlasFrames != null)
			return graphics.atlasFrames;
		
		if ((graphics == null) || (Description == null)) return null;
		
		var frames:AtlasFrames = new AtlasFrames(graphics);
		
		var data:Fast = new haxe.xml.Fast(Xml.parse(Description).firstElement());
		
		for (texture in data.nodes.SubTexture)
		{
			var angle:Float = 0;
			var name:String = texture.att.name;
			var trimmed:Bool = texture.has.frameX;
			
			var rect:Rectangle = new Rectangle(
				Std.parseFloat(texture.att.x), Std.parseFloat(texture.att.y),
				Std.parseFloat(texture.att.width), Std.parseFloat(texture.att.height));
			
			var size:Rectangle = if (trimmed)
					new Rectangle(
						Std.parseInt(texture.att.frameX), Std.parseInt(texture.att.frameY),
						Std.parseInt(texture.att.frameWidth), Std.parseInt(texture.att.frameHeight));
				else 
					new Rectangle(0, 0, rect.width, rect.height);
					
			var offset:FlxPoint = FlxPoint.get(-size.left, -size.top);
			var sourceSize:FlxPoint = FlxPoint.get(size.width, size.height);
			
			frames.addAtlasFrame(rect, sourceSize, offset, name, angle);
		}
		
		graphics.atlasFrames = frames;
		return frames;
	}
	
	/**
	 * Parsing method for TexturePacker atlases in xml format
	 * (trimmed images aren't supported yet for this type of atlas)
	 * @param	Source			the image source (can be FlxGraphic, String, Class<Dynamic>, BitmapData, FlxFrame or FlxFramesCollection)
	 * @param	Description		contents of xml file with atlas description. You can get it with Assets.getText(path/to/description.xml)
	 * @return	Newly created AtlasFrames collection
	 */
	public static function texturePackerXML(Source:Dynamic, Description:String):AtlasFrames
	{
		var graphics:FlxGraphic = FlxGraphic.resolveSource(Source);
		
		// No need to parse data again
		if (graphics.atlasFrames != null)
			return graphics.atlasFrames;
		
		if ((graphics == null) || (Description == null)) return null;
		
		var frames:AtlasFrames = new AtlasFrames(graphics);
		
		var xml = Xml.parse(Description);
		var root = xml.firstElement();
		
		for (sprite in root.elements())
		{
			// trimmed images aren't supported yet for this type of atlas
			var rotated:Bool = (sprite.exists("r") && sprite.get("r") == "y");
			var angle:Float = (rotated) ? -90 : 0;
			var name:String = sprite.get("n");
			var offset:FlxPoint = FlxPoint.get(0, 0);
			
			var rect:Rectangle = new Rectangle(	
											Std.parseInt(sprite.get("x")),
											Std.parseInt(sprite.get("y")),
											Std.parseInt(sprite.get("w")),
											Std.parseInt(sprite.get("h"))
										);
			
			var sourceSize:FlxPoint = FlxPoint.get(rect.width, rect.height);
			
			frames.addAtlasFrame(rect, sourceSize, offset, name, angle);
		}
		
		graphics.atlasFrames = frames;
		return frames;
	}
}