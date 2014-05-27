package flixel.system.frontEnds;

import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.system.FlxAssets;
import flixel.util.FlxBitmapUtil;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphics;
import flixel.util.loaders.TextureRegion;
import openfl.Assets;

/**
 * Internal storage system to prevent graphics from being used repeatedly in memory.
 */
class BitmapFrontEnd
{
	@:allow(flixel.system.frontEnds.BitmapLogFrontEnd)
	private var _cache:Map<String, FlxGraphics>;
	
	public function new()
	{
		clearCache();
	}
	
	#if FLX_RENDER_TILE
	public var whitePixel(get, null):FlxGraphics;
	
	private var _whitePixel:FlxGraphics;
	
	private function get_whitePixel():FlxGraphics
	{
		if (_whitePixel == null)
		{
			var bd:BitmapData = new BitmapData(2, 2, true, FlxColor.WHITE);
			_whitePixel = new FlxGraphics("whitePixel", bd, true);
			_whitePixel.persist = true;
			_whitePixel.tilesheet.addTileRect(new Rectangle(0, 0, 1, 1), new Point(0, 0));
		}
		
		return _whitePixel;
	}
	
	public function onContext():Void
	{
		var obj:FlxGraphics;
		
		if (_cache != null)
		{
			for (key in _cache.keys())
			{
				obj = _cache.get(key);
				if (obj != null && obj.isDumped)
				{
					obj.onContext();
				}
			}
		}
	}
	#end
	
	/**
	 * Dumps bits of all graphics in the cache. This restores memory, but you can't read / write pixels on those graphics anymore.
	 * You can call onContext() method for each FlxGraphic object which will restore it again.
	 */
	public function dumpCache():Void
	{
		#if !(flash || js)
		var obj:FlxGraphics;
		
		if (_cache != null)
		{
			for (key in _cache.keys())
			{
				obj = _cache.get(key);
				if (obj != null && obj.canBeDumped)
				{
					obj.dump();
				}
			}
		}
		#end
	}
	
	/**
	 * Check the local bitmap cache to see if a bitmap with this key has been loaded already.
	 * 
	 * @param	Key		The string key identifying the bitmap.
	 * @return	Whether or not this file can be found in the cache.
	 */
	public inline function checkCache(Key:String):Bool
	{
		return (_cache.exists(Key) && (_cache.get(Key) != null));
	}
	
	/**
	 * Generates a new BitmapData object (a colored square) and caches it.
	 * 
	 * @param	Width	How wide the square should be.
	 * @param	Height	How high the square should be.
	 * @param	Color	What color the square should be (0xAARRGGBB)
	 * @param	Unique	Ensures that the bitmap data uses a new slot in the cache.
	 * @param	Key		Force the cache to use a specific Key to index the bitmap.
	 * @return	The BitmapData we just created.
	 */
	public function create(Width:Int, Height:Int, Color:Int, Unique:Bool = false, ?Key:String):FlxGraphics
	{
		var key:String = Key;
		if (key == null)
		{
			key = Width + "x" + Height + ":" + Color;
			if (Unique && checkCache(key))
			{
				key = getUniqueKey(key);
			}
		}
		if (!checkCache(key))
		{
			_cache.set(key, new FlxGraphics(key, new BitmapData(Width, Height, true, Color)));
		}
		
		return _cache.get(key);
	}
	
	/**
	 * Loads a bitmap from a file, clones it if necessary and caches it.
	 * 
	 * @param	Graphic		The image file that you want to load.
	 * @param	Unique		Ensures that the bitmap data uses a new slot in the cache.
	 * @param	Key			Force the cache to use a specific Key to index the bitmap.
	 * @return	The FlxGraphics we just created.
	 */
	public inline function add(Graphic:Dynamic, Unique:Bool = false, ?Key:String):FlxGraphics
	{
		return addWithSpaces(Graphic, 0, 0, 1, 1, Unique, Key);
	}
	
	/**
	 * Loads a bitmap from a file, inserts spaces between frames and caches it.
	 * Could be useful for native targets to remove possible glitches.
	 * 
	 * @param	Graphic			The image file that you want to load.
	 * @param	FrameWidth		The width of frames in image
	 * @param	FrameHeight		The height of frames in image
	 * @param	SpacingX		Horizontal spaces to insert between frames in image
	 * @param	SpacingY		Vertical spaces to insert between frames in image
	 * @param	Unique			Ensures that the bitmap data uses a new slot in the cache.
	 * @param	Key				Force the cache to use a specific Key to index the bitmap.
	 * @return	The FlxGraphics we just created.
	 */
	
	// TODO: think about this method and add() method
	public function addWithSpaces(Graphic:Dynamic, FrameWidth:Int, FrameHeight:Int, SpacingX:Int = 1, SpacingY:Int = 1, Unique:Bool = false, ?Key:String):FlxGraphics
	{
		if (Graphic == null)
		{
			return null;
		}
		
		var region:TextureRegion = null;
		var graphic:FlxGraphics = null;
		
		var isClass:Bool = false;
		var isBitmap:Bool = false;
		var isRegion:Bool = false;
		var isGraphics:Bool = false;
		
		if (Std.is(Graphic, FlxGraphics))
		{
			isGraphics = true;	
			graphic = cast(Graphic, FlxGraphics);
			
			if (!Unique && (FrameWidth <= 0 && FrameHeight <= 0))
			{
				return graphic;
			}
		}
		else if (Std.is(Graphic, Class))
		{
			isClass = true;
		}
		else if (Std.is(Graphic, BitmapData))
		{
			isBitmap = true;
		}
		else if (Std.is(Graphic, TextureRegion))
		{
			isRegion = true;
			region = cast(Graphic, TextureRegion);
		}
		else if (Std.is(Graphic, String))
		{
			// don't need to set any of the flags
		}
		else
		{
			return null;
		}
		
		var additionalKey:String = "";
		
		if (FrameWidth > 0 || FrameHeight > 0)
		{
			additionalKey = "FrameSize:" + FrameWidth + "_" + FrameHeight + "_Spacing:" + SpacingX + "_" + SpacingY;
		}
		
		var key:String = Key;
		if (key == null)
		{
			if (isClass)
			{
				key = Type.getClassName(cast(Graphic, Class<Dynamic>));
			}
			else if (isBitmap)
			{
				if (!Unique)
				{
					key = getCacheKeyFor(cast Graphic);
					if (key == null)
					{
						key = getUniqueKey();
					}
				}
			}
			else if (isRegion)
			{
				key = region.data.key;
			}
			else if (isGraphics)
			{
				key = graphic.key; 
			}
			else
			{
				key = Graphic;
			}
			
			key += additionalKey;
			
			if (Unique)
			{
				key = getUniqueKey((key == null) ? "pixels" : key);
			}
		}
		
		// If there is no data for this key, generate the requested graphic
		if (!checkCache(key))
		{
			var bd:BitmapData = null;
			if (isClass)
			{
				bd = Type.createInstance(cast(Graphic, Class<Dynamic>), [0, 0]);
			}
			else if (isBitmap)
			{
				bd = cast Graphic;
			}
			else if (isRegion)
			{
				bd = region.data.bitmap;
			}
			else if (isGraphics)
			{
				bd = graphic.bitmap;
			}
			else
			{
				bd = FlxAssets.getBitmapData(Graphic);
			}
			
			if (FrameWidth > 0 || FrameHeight > 0)
			{
				bd = FlxBitmapUtil.addSpacing(bd, 
						new Point(FrameWidth, FrameHeight), 
						new Point(SpacingX, SpacingY));
			}
			else if (Unique)
			{
				bd = bd.clone();
			}
			
			var graph:FlxGraphics = new FlxGraphics(key, bd);
			
			if (isClass && !Unique)
			{
				graph.assetsClass = cast Graphic;
			}
			else if (!isClass && !isBitmap && !isRegion && !Unique)
			{
				graph.assetsKey = cast Graphic;
			}
			
			_cache.set(key, graph);
		}
		
		return _cache.get(key);
	}
	
	/**
	 * Gets FlxGraphics object from this storage by specified key. 
	 * @param	key	Key for FlxGraphics object (it's name)
	 * @return	FlxGraphics with the key name, or null if there is no such object
	 */
	public function get(key:String):FlxGraphics
	{
		return _cache.get(key);
	}
	
	/**
	 * Gets key from bitmap cache for specified bitmapdata
	 * 
	 * @param	bmd	bitmapdata to find in cache
	 * @return	bitmapdata's key or null if there isn't such bitmapdata in cache
	 */
	public function getCacheKeyFor(bmd:BitmapData):String
	{
		for (key in _cache.keys())
		{
			var data:BitmapData = _cache.get(key).bitmap;
			if (data == bmd)
			{
				return key;
			}
		}
		return null;
	}
	
	/**
	 * Gets unique key for bitmap cache
	 * 
	 * @param	baseKey	key's prefix
	 * @return	unique key
	 */
	public function getUniqueKey(baseKey:String = "pixels"):String
	{
		if (checkCache(baseKey))
		{
			var inc:Int = 0;
			var ukey:String;
			do
			{
				ukey = baseKey + inc++;
			} while (checkCache(ukey));
			baseKey = ukey;
		}
		return baseKey;
	}
	
	/**
	 * 
	 * @param	baseKey
	 * @param	frameSize
	 * @param	frameSpacing
	 * @param	region
	 * @return
	 */
	// TODO: document it
	// TODO: use it somewhere
	public function getKeyWithSpacings(baseKey:String, frameSize:Point, frameSpacing:Point, region:Rectangle = null):String
	{
		var result:String = baseKey;
		
		if (region != null)
		{
			result += "_Region:" + region.x + "_" + region.y + "_" + region.width + "_" + region.height;
		}
		
		result += "_FrameSize:" + frameSize.x + "_" + frameSize.y + "_Spacing:" + frameSpacing.x + "_" + frameSpacing.y;
		return result;
	}
	
	public function remove(key:String):Void
	{
		if ((key != null) && _cache.exists(key))
		{
			var obj:FlxGraphics = _cache.get(key);
			#if !nme
			Assets.cache.bitmapData.remove(key);
			#end
			_cache.remove(key);
			obj.destroy();
		}
	}
	
	/**
	 * Dumps the cache's image references.
	 */
	public function clearCache():Void
	{
		var obj:FlxGraphics;
		
		if (_cache == null)
		{
			_cache = new Map();
		}

		for (key in _cache.keys())
		{
			obj = _cache.get(key);
			if (obj != null && !obj.persist)
			{
				#if !nme
				Assets.cache.bitmapData.remove(key);
				#end
				_cache.remove(key);
				obj.destroy();
				obj = null;
			}
		}
	}
	
	/**
	 * Removes all unused graphics from cache,
	 * but skips graphics which should persist in cache and shouldn't be destroyed on no use.
	 */
	public function clearUnused():Void
	{
		var obj:FlxGraphics;
		
		if (_cache != null)
		{
			for (key in _cache.keys())
			{
				obj = _cache.get(key);
				if (obj != null && obj.useCount <= 0 && !obj.persist && obj.destroyOnNoUse)
				{
					remove(obj.key);
				}
			}
		}
	}
}
