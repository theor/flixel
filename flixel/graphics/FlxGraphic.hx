package flixel.graphics;

import flash.display.BitmapData;
import flixel.FlxG;
import flixel.system.FlxAssets;
import flixel.graphics.frames.AtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.ImageFrame;
import flixel.graphics.frames.SpritesheetFrames;
import flixel.system.layer.TileSheetExt;
import flixel.util.FlxDestroyUtil;

class FlxGraphic
{
	/**
	 * Key in BitmapFrontEnd cache
	 */
	public var key:String;
	/**
	 * Cached BitmapData object
	 */
	public var bitmap:BitmapData;
	
	/**
	 * The size of cached BitmapData.
	 * Added for faster access/typing
	 */
	public var width(default, null):Int = 0;
	
	public var height(default, null):Int = 0;
	
	/**
	 * Asset name from openfl.Assets
	 */
	public var assetsKey:String;
	/**
	 * Class name for the BitmapData
	 */
	public var assetsClass:Class<BitmapData>;
	
	/**
	 * Whether this graphics object should stay in cache after state changes or not.
	 */
	public var persist:Bool = false;
	/**
	 * Whether we should destroy this FlxGraphic object when useCount become zero.
	 * Default is true.
	 */
	public var destroyOnNoUse(get, set):Bool;
	
	/**
	 * Whether the BitmapData of this graphics object has been dumped or not.
	 */
	public var isDumped(default, null):Bool = false;
	/**
	 * Whether the BitmapData of this graphics object can be dumped for decreased memory usage,
	 * but may cause some issues (when you need direct access to pixels of this graphics.
	 * If the graphics is dumped then you should call undump() and have total access to pixels.
	 */
	public var canBeDumped(get, never):Bool;
	
	#if FLX_RENDER_TILE
	/**
	 * Tilesheet for this graphics object. It is used only for FLX_RENDER_TILE mode
	 */
	public var tilesheet(get, null):TileSheetExt;
	#end
	
	/**
	 * Usage counter for this FlxGraphic object.
	 */
	public var useCount(get, set):Int;
	
	/**
	 * ImageFrame object for the whole bitmap
	 */
	public var imageFrame(get, null):ImageFrame;
	
	/**
	 * Atlas frames for this graphics.
	 * You should fill it yourself with one of the AtlasFrames static methods
	 * (like texturePackerJSON(), texturePackerXML(), sparrow(), libGDX()).
	 */
	public var atlasFrames:AtlasFrames;
	
	/**
	 * Collection of all ImageFrame objects created for this graphics
	 */
	public var imageFrames:Array<ImageFrame>;
	
	/**
	 * Collection of all SpritesheetFrame objects for this graphics
	 */
	public var spritesheetFrames:Array<SpritesheetFrames>;
	
	/**
	 * Internal var holding ImageFrame for the whole bitmap of this graphics.
	 * Use public imageFrame var to access/generate it.
	 */
	private var _imageFrame:ImageFrame;
	
	#if FLX_RENDER_TILE
	/**
	 * Internal var holding Tilesheet for bitmap of this graphics.
	 * It is used only in FLX_RENDER_TILE mode
	 */
	private var _tilesheet:TileSheetExt;
	#end
	
	private var _useCount:Int = 0;
	
	private var _destroyOnNoUse:Bool = true;
	
	/**
	 * FlxGraphic constructor
	 * @param	Key			key string for this graphics object, with which you can get it from bitmap cache
	 * @param	Bitmap		BitmapData for this graphics object
	 * @param	Persist		Whether or not this graphics stay in the cache after reseting cache. Default value is false which means that this graphics will be destroyed at the cache reset.
	 */
	@:allow(flixel.system.frontEnds.BitmapFrontEnd)
	private function new(Key:String, Bitmap:BitmapData, Persist:Bool = false)
	{
		key = Key;
		bitmap = Bitmap;
		persist = Persist;
		
		width = bitmap.width;
		height = bitmap.height;
		
		spritesheetFrames = new Array<SpritesheetFrames>();
		imageFrames = new Array<ImageFrame>();
	}
	
	/**
	 * Dumps bits of bitmapdata == less memory, but you can't read/write pixels on it anymore
	 * (but you can call onContext() (or undump()) method which will restore it again)
	 */
	public function dump():Void
	{
		#if (FLX_RENDER_TILE && !flash && !nme)
		if (canBeDumped)
		{
			bitmap.dumpBits();
			isDumped = true;
		}
		#end
	}
	
	/**
	 * Undumps bits of bitmapdata - regenerates it and regenerate tilesheet data for this object
	 */
	public function undump():Void
	{
		#if (FLX_RENDER_TILE && !flash && !nme)
		if (isDumped)
		{
			var newBitmap:BitmapData = getBitmapFromSystem();
			
			if (newBitmap != null)
			{
				bitmap = newBitmap;
				if (_tilesheet != null)
				{
					_tilesheet = TileSheetExt.rebuildFromOld(_tilesheet, this);
				}
			}
			
			isDumped = false;
		}
		#end
	}
	
	/**
	 * Use this method to restore cached bitmapdata (if it's possible).
	 * It's called automatically when the RESIZE event occurs.
	 */
	public function onContext():Void
	{
		// no need to restore tilesheet if it haven't been dumped
		if (isDumped)
		{
			undump();	// restore everything
			dump();		// and dump bitmapdata again
		}
	}
	
	/**
	 * Trying to free the memory as much as possible
	 */
	public function destroy():Void
	{
		bitmap = FlxDestroyUtil.dispose(bitmap);
		#if FLX_RENDER_TILE
		_tilesheet = FlxDestroyUtil.destroy(_tilesheet);
		#end
		key = null;
		assetsKey = null;
		assetsClass = null;
		
		_imageFrame = null;	// no need to dispose _imageFrame since it exists in imageFrames
		
		imageFrames = FlxDestroyUtil.destroyArray(imageFrames);
		spritesheetFrames = FlxDestroyUtil.destroyArray(spritesheetFrames);
		atlasFrames = FlxDestroyUtil.destroy(atlasFrames);
	}
	
	#if FLX_RENDER_TILE
	/**
	 * Tilesheet getter. Generates new one (and regenerates) if there is no tilesheet for this graphics yet.
	 */
	private function get_tilesheet():TileSheetExt
	{
		if (_tilesheet == null)
		{
			var dumped:Bool = isDumped;
			
			if (dumped)	undump();
			
			_tilesheet = new TileSheetExt(bitmap);
			
			if (dumped)	dump();
		}
		
		return _tilesheet;
	}
	#end
	
	/**
	 * Gets BitmapData for this graphics object from OpenFl.
	 * This method is used for undumping graphics.
	 */
	private function getBitmapFromSystem():BitmapData
	{
		var newBitmap:BitmapData = null;
		if (assetsClass != null)
		{
			newBitmap = Type.createInstance(cast(assetsClass, Class<Dynamic>), []);
		}
		else if (assetsKey != null)
		{
			newBitmap = FlxAssets.getBitmapData(assetsKey);
		}
		
		return newBitmap;
	}
	
	private inline function get_canBeDumped():Bool
	{
		return ((assetsClass != null) || (assetsKey != null));
	}
	
	private function get_useCount():Int
	{
		return _useCount;
	}
	
	private function set_useCount(Value:Int):Int
	{
		if ((Value <= 0) && _destroyOnNoUse && !persist)
		{
			FlxG.bitmap.remove(key);
		}
		
		return _useCount = Value;
	}
	
	private function get_destroyOnNoUse():Bool
	{
		return _destroyOnNoUse;
	}
	
	private function set_destroyOnNoUse(Value:Bool):Bool
	{
		if (Value && _useCount == 0 && key != null && !persist)
		{
			FlxG.bitmap.remove(key);
		}
		
		return _destroyOnNoUse = Value;
	}
	
	private function get_imageFrame():ImageFrame
	{
		if (_imageFrame == null)
		{
			_imageFrame = ImageFrame.fromRectangle(this, bitmap.rect);
		}
		
		return _imageFrame;
	}
	
	/**
	 * Gets FlxGraphic object for specified Source object
	 * @param	Source	You can specify FlxGraphic, BitmapData, String (asset path), Class<Dynamic>, FlxFramesCollection or FlxFrame as a source
	 * @return	graphics object for specified source
	 */
	public static function resolveSource(Source:Dynamic):FlxGraphic
	{
		if (Source == null)
		{
			return null;
		}
		
		if (Std.is(Source, FlxGraphic))
		{
			return cast Source;
		}
		else if (Std.is(Source, BitmapData) || Std.is(Source, String) || Std.is(Source, Class))
		{
			return FlxG.bitmap.add(Source);
		}
		else if (Std.is(Source, FlxFramesCollection))
		{
			return cast(Source, FlxFramesCollection).parent;
		}
		else if (Std.is(Source, FlxFrame))
		{
			return cast(Source, FlxFrame).parent;
		}
		
		return null;
	}
}