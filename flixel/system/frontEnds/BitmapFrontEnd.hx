package flixel.system.frontEnds;

import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.ImageFrame;
import flixel.system.FlxAssets;
import flixel.util.FlxBitmapUtil;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import flixel.util.loaders.TextureRegion;
import openfl.Assets;

/**
 * Internal storage system to prevent graphics from being used repeatedly in memory.
 */
class BitmapFrontEnd
{
	@:allow(flixel.system.frontEnds.BitmapLogFrontEnd)
	private var _cache:Map<String, FlxGraphic>;
	
	public function new()
	{
		clearCache();
	}
	
	#if FLX_RENDER_TILE
	/**
	 * Helper FlxFrame object. Containing only one frame.
	 * Useful for drawing colored rectangles of all sizes in FLX_RENDER_TILE mode
	 */
	public var whitePixel(get, null):FlxFrame;
	
	private var _whitePixel:FlxFrame;
	
	private function get_whitePixel():FlxFrame
	{
		if (_whitePixel == null)
		{
			var bd:BitmapData = new BitmapData(2, 2, true, FlxColor.WHITE);
			var graphic:FlxGraphic = new FlxGraphic("whitePixel", bd, true);
			graphic.persist = true;
			_whitePixel = ImageFrame.fromRectangle(graphic, new Rectangle(0, 0, 2, 2)).frame;
			// TODO: make changes to classes which use _whitePixel (FlxBitmapTextField)
			// _whitePixel.tilesheet.addTileRect(new Rectangle(0, 0, 1, 1), new Point(0, 0));
		}
		
		return _whitePixel;
	}
	
	/**
	 * New context handler.
	 * Regenerates tilesheets for all dumped graphics objects in the cache
	 */
	public function onContext():Void
	{
		var obj:FlxGraphic;
		
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
	 * Dumps bits of all graphics in the cache. This frees some memory, but you can't read/write pixels on those graphics anymore.
	 * You can call undump() method for each FlxGraphic (or undumpCache()) object which will restore it again.
	 */
	public function dumpCache():Void
	{
		#if !(flash || js)
		var obj:FlxGraphic;
		
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
	 * Restores graphics of all dumped objects in the cache.
	 */
	public function undumpCache():Void
	{
		#if !(flash || js)
		var obj:FlxGraphic;
		
		if (_cache != null)
		{
			for (key in _cache.keys())
			{
				obj = _cache.get(key);
				if (obj != null && obj.isDumped)
				{
					obj.undump();
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
	 * Generates a new BitmapData object (a colored rectangle) and caches it.
	 * 
	 * @param	Width	How wide the rectangle should be.
	 * @param	Height	How high the rectangle should be.
	 * @param	Color	What color the rectangle should be (0xAARRGGBB)
	 * @param	Unique	Ensures that the bitmap data uses a new slot in the cache.
	 * @param	Key		Force the cache to use a specific Key to index the bitmap.
	 * @return	The BitmapData we just created.
	 */
	public function create(Width:Int, Height:Int, Color:Int, Unique:Bool = false, ?Key:String):FlxGraphic
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
			_cache.set(key, new FlxGraphic(key, new BitmapData(Width, Height, true, Color)));
		}
		
		return _cache.get(key);
	}
	
	/**
	 * Loads a bitmap from a file, clones it if necessary and caches it.
	 * 
	 * @param	Graphic		The image file that you want to load.
	 * @param	Unique		Ensures that the bitmap data uses a new slot in the cache.
	 * @param	Key			Force the cache to use a specific Key to index the bitmap.
	 * @return	The FlxGraphic we just created.
	 */
	public function add(Graphic:Dynamic, Unique:Bool = false, ?Key:String):FlxGraphic
	{
		if (Graphic == null)
		{
			return null;
		}
		
		var graphic:FlxGraphic = null;
		var isClass:Bool = false;
		var isBitmap:Bool = false;
		var isGraphic:Bool = false;
		var isFrameCollection:Bool = false;
		var isFrame:Bool = false;
		
		if (Std.is(Graphic, FlxGraphic))
		{
			isGraphic = true;	
			graphic = cast(Graphic, FlxGraphic);
		}
		else if (Std.is(Graphic, FlxFramesCollection))
		{
			isFrameCollection = true;
			graphic = cast(Graphic, FlxFramesCollection).parent;
		}
		else if (Std.is(Graphic, FlxFrame))
		{
			isFrameCollection = true;
			graphic = cast(Graphic, FlxFrame).parent;
		}
		else if (Std.is(Graphic, Class))
		{
			isClass = true;
		}
		else if (Std.is(Graphic, BitmapData))
		{
			isBitmap = true;
		}
		else if (Std.is(Graphic, String))
		{
			// don't need to set any of the flags
		}
		else
		{
			return null;
		}
		
		if (graphic != null && !Unique)
		{
			return graphic;
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
			else if (isGraphic || isFrameCollection || isFrame)
			{
				key = graphic.key; 
			}
			else // Graphic is String
			{
				key = Graphic;	
			}
			
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
			else if (isGraphic || isFrameCollection || isFrame)
			{
				bd = graphic.bitmap;
			}
			else	// Graphic is String
			{
				bd = FlxAssets.getBitmapData(Graphic);
			}
			
			if (Unique)
			{
				bd = bd.clone();
			}
			
			var graph:FlxGraphic = new FlxGraphic(key, bd);
			
			if (isClass && !Unique)
			{
				graph.assetsClass = cast Graphic;
			}
			else if (!isClass && !isBitmap && !isFrameCollection && !isFrame && !Unique)
			{
				graph.assetsKey = cast Graphic;
			}
			
			_cache.set(key, graph);
		}
		
		return _cache.get(key);
	}
	
	/**
	 * Gets FlxGraphic object from this storage by specified key. 
	 * @param	key	Key for FlxGraphic object (it's name)
	 * @return	FlxGraphic with the key name, or null if there is no such object
	 */
	public function get(key:String):FlxGraphic
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
	 * Generates key from provided base key and information about tile size and offsets in spritesheet 
	 * and the region of image to use as spritesheet graphics source.
	 * 
	 * @param	baseKey			Beginning of the key. Usually it is the key for original spritesheet graphics (like "assets/tile.png") 
	 * @param	frameSize		the size of tile in spritesheet
	 * @param	frameSpacing	offsets between tiles in offsets
	 * @param	region			region of image to use as spritesheet graphics source
	 * @return	Generated key for spritesheet with inserted spaces between tiles
	 */
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
	
	/**
	 * Totally removes FlxGraphic object with specified key.
	 * @param	key	the key for cached FlxGraphic object.
	 */
	public function remove(key:String):Void
	{
		if ((key != null) && _cache.exists(key))
		{
			var obj:FlxGraphic = _cache.get(key);
			#if !nme
			Assets.cache.bitmapData.remove(key);
			#end
			_cache.remove(key);
			obj.destroy();
		}
	}
	
	/**
	 * Clears image cache (and destroys those images).
	 * Graphics object will be removed and destroyed only if it shouldn't persist in the cache
	 */
	public function clearCache():Void
	{
		var obj:FlxGraphic;
		
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
		var obj:FlxGraphic;
		
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