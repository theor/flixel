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
	
	// TODO: add vars which reflects type of object loaded last	
	// TODO: use these vars
	public var isLastFrame:Bool = false;
	public var isLastFramesCollection:Bool = false;
	
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
		var key:String = (Key != null) ? Key : (Width + "x" + Height + ":" + Color);
		if (Unique)
		{
			key = getUniqueKey(key);
		}
		
		if (!checkCache(key))
		{
			_cache.set(key, new FlxGraphic(key, new BitmapData(Width, Height, true, Color)));
		}
		
		return _cache.get(key);
	}
	
	/**
	 * Gets the key for provided graphic source.
	 * 
	 * @param	?Graphic		Optional FlxGraphics object to create FlxGraphic from.
	 * @param	?Frame			Optional FlxFrame object to create FlxGraphic from.
	 * @param	?Frames			Optional FlxFramesCollection object to create FlxGraphic from.
	 * @param	?Bitmap			Optional BitmapData object to create FlxGraphic from.
	 * @param	?BitmapClass	Optional Class for BitmapData to create FlxGraphic from.
	 * @param	?Str			Optional String key to use for FlxGraphic instantiation.
	 * @param	Unique			Ensures that the bitmap data uses a new slot in the cache.
	 * @param	Key				Force the cache to use a specific Key to index the bitmap.
	 * 
	 * @return	Key string, which could be used for caching of provided graphic.
	 */
	public function resolveKey(	?Graphic:FlxGraphic, ?Frame:FlxFrame, ?Frames:FlxFramesCollection, 
								?Bitmap:BitmapData, ?BitmapClass:Class<Dynamic>, ?Str:String,
								Unique:Bool = false, ?Key:String):String
	{
		var key:String = Key;
		
		if (key == null)
		{
			if (Str != null)
			{
				key = Str;
			}
			else if (Bitmap != null)
			{
				key = findKeyForBitmap(Bitmap);
			}
			else if (Graphic != null)
			{
				key = Graphic.key;
			}
			else if (BitmapClass != null)
			{
				key = Type.getClassName(BitmapClass);
			}
			else if (Frames != null)
			{
				key = Frames.parent.key;
			}
			else if (Frame != null)
			{
				key = Frame.parent.key;
			}
		}
		
		if (key == null || Unique)
		{
			key = getUniqueKey(key);
		}
		
		return key;
	}
	
	/**
	 * Gets the bitmap for provided graphic.
	 * 
	 * @param	?Graphic		Optional FlxGraphics object to create FlxGraphic from.
	 * @param	?Frame 			Optional FlxFrame object to create FlxGraphic from.
	 * @param	?Frames			Optional FlxFramesCollection object to create FlxGraphic from.
	 * @param	?Bitmap			Optional BitmapData object to create FlxGraphic from.
	 * @param	?BitmapClass	Optional Class for BitmapData to create FlxGraphic from.
	 * @param	?Str			Optional String key to use for FlxGraphic instantiation.
	 * 
	 * @return	BitmapData object for provided graphic source.
	 */
	public function resolveBitmap(	?Graphic:FlxGraphic, ?Frame:FlxFrame, ?Frames:FlxFramesCollection, 
									?Bitmap:BitmapData, ?BitmapClass:Class<Dynamic>, ?Str:String):BitmapData
	{
		var bd:BitmapData = null;
		
		if (Str != null)
		{
			bd = FlxAssets.getBitmapData(Str);
		}
		else if (Bitmap != null)
		{
			bd = Bitmap;
		}
		else if (Graphic != null)
		{
			bd = Graphic.bitmap;
		}
		else if (BitmapClass != null)
		{
			bd = Type.createInstance(BitmapClass, [0, 0]);
		}
		else if (Frames != null)
		{
			bd = Frames.parent.bitmap;
		}
		else if (Frame != null)
		{
			bd = Frame.parent.bitmap;
		}
		
		return bd;
	}
	
	/**
	 * Creates (or gets from cache) graphic from provided BitmapData
	 * @param	Bitmap			BitmapData for FlxGraphic object
	 * @param	Unique			Do we need to create new one FlxGraphic object even if there is one already
	 * @param	Key				Key string which will be used for caching of FlxGraphic object
	 * @param	?AssetKey		
	 * @param	?AssetClass
	 * @return	Created and cached FlxGraphic object for provided BitmapData.
	 */
	public function resolveGraphic(Bitmap:BitmapData, Unique:Bool = false, Key:String, ?AssetKey:String, ?AssetClass:Class<BitmapData>):FlxGraphic
	{
		if (Key == null)
		{
			return null;
		}
		
		if (!checkCache(Key))
		{
			if (Bitmap == null)
			{
				return null;
			}
			
			if (Unique)
			{
				Bitmap = Bitmap.clone();
			}
			
			var graph:FlxGraphic = new FlxGraphic(Key, Bitmap);
			
			// TODO: add unique property to FlxGraphic object, 
			// so if it will be regenerated, then it will have unique graphic again
			graph.assetsKey = AssetKey;
			
			if (AssetClass != null)
			{
				graph.assetsClass = cast AssetClass;
			}
			
			_cache.set(Key, graph);
		}
		
		return _cache.get(Key);
	}
	
	/**
	 * Loads a bitmap from a file, clones it if necessary and caches it.
	 * @param	?Graphic		Optional FlxGraphics object to create FlxGraphic from.
	 * @param	?Frame			Optional FlxFrame object to create FlxGraphic from.
	 * @param	?Frames			Optional FlxFramesCollection object to create FlxGraphic from.
	 * @param	?Bitmap			Optional BitmapData object to create FlxGraphic from.
	 * @param	?BitmapClass	Optional Class for BitmapData to create FlxGraphic from.
	 * @param	?Str			Optional String key to use for FlxGraphic instantiation.
	 * @param	Unique			Ensures that the bitmap data uses a new slot in the cache.
	 * @param	Key				Force the cache to use a specific Key to index the bitmap.
	 * @return	The FlxGraphic we just created.
	 */
	public function add(	?Graphic:FlxGraphic, ?Frame:FlxFrame, ?Frames:FlxFramesCollection, 
							?Bitmap:BitmapData, ?BitmapClass:Class<BitmapData>, ?Str:String,
							Unique:Bool = false, ?Key:String):FlxGraphic
	{
		var key:String = resolveKey(Graphic, Frame, Frames, Bitmap, BitmapClass, Str, Unique, Key);
		
		if (checkCache(key))
		{
			return _cache.get(key);
		}
		
		var bitmap:BitmapData = resolveBitmap(Graphic, Frame, Frames, Bitmap, BitmapClass, Str);
		return resolveGraphic(bitmap, Unique, key, Str, BitmapClass);
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
	public function findKeyForBitmap(bmd:BitmapData):String
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
	public function getUniqueKey(baseKey:String = null):String
	{
		if (baseKey == null) baseKey = "pixels";
		
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