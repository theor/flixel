package flixel.graphics;

import flash.display.BitmapData;
import flixel.FlxG;
import flixel.system.FlxAssets;
import flixel.graphics.frames.AtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxSpriteFrames;
import flixel.graphics.frames.ImageFrame;
import flixel.graphics.frames.SpritesheetFrames;
import flixel.system.layer.TileSheetExt;
import flixel.util.FlxDestroyUtil;

class FlxGraphics
{
	/**
	 * Key in BitmapFrontEnd cache
	 */
	public var key:String;
	/**
	 * Cached BitmapData object
	 */
	public var bitmap:BitmapData;
	
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
	 * Whether this cached object should stay in cache after state changes or not.
	 */
	public var persist:Bool = false;
	/**
	 * Whether we should destroy this FlxGraphics object when useCount become zero.
	 * Default is false.
	 */
	public var destroyOnNoUse(get, set):Bool;
	
	/**
	 * Whether the BitmapData of this cached object has been dumped or not.
	 */
	public var isDumped(default, null):Bool = false;
	/**
	 * Whether the BitmapData of this cached object can be dumped for decreased memory usage.
	 */
	public var canBeDumped(get, never):Bool;
	
	public var tilesheet(get, null):TileSheetExt;
	
	/**
	 * Usage counter for this FlxGraphics object.
	 */
	public var useCount(get, set):Int;
	
	// TODO: use these vars (somehow)
	public var imageFrame(get, null):ImageFrame;
	
	public var atlasFrames:AtlasFrames;
	
	public var imageFrames:Array<ImageFrame>;
	
	public var spritesheetFrames:Array<SpritesheetFrames>;
	
	private var _imageFrame:ImageFrame;
	
	private var _tilesheet:TileSheetExt;
	
	private var _useCount:Int = 0;
	
	private var _destroyOnNoUse:Bool = true;
	
	public function new(Key:String, Bitmap:BitmapData, Persist:Bool = false)
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
	 * Dumps bits of bitmapdata = less memory, but you can't read / write pixels on it anymore
	 * (but you can call onContext() method which will restore it again)
	 */
	// TODO: dump() and undump() should be available only
	// on openfl (i.e. add #if !nme compiler conditional)
	public function dump():Void
	{
		#if (FLX_RENDER_TILE && !flash)
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
		#if FLX_RENDER_TILE
		if (isDumped)
		{
			var newBitmap:BitmapData = getBitmapFromSystem();
			
			if (newBitmap != null)
			{
				bitmap = newBitmap;
				if (_tilesheet != null)
				{
					_tilesheet = TileSheetExt.rebuildFromOld(_tilesheet, this);
					
					// TODO: "regen" frames (set their tilesheets)
					
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
			dump();	// and dump bitmapdata again
		}
	}
	
	public function destroy():Void
	{
		_tilesheet = FlxDestroyUtil.destroy(_tilesheet);
		bitmap = FlxDestroyUtil.dispose(bitmap);
		key = null;
		assetsKey = null;
		assetsClass = null;
		
		// TODO: destroy all frames and their collections
		// do it here or in TilesheetExt
	}
	
	private function get_tilesheet():TileSheetExt
	{
		if (_tilesheet == null)
		{
			if (isDumped)
			{
				onContext();
			}
			
			_tilesheet = new TileSheetExt(bitmap);
		}
		
		return _tilesheet;
	}
	
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
	
	public static function resolveSource(Source:Dynamic):FlxGraphics
	{
		if (Source == null)
		{
			return null;
		}
		
		if (Std.is(Source, FlxGraphics))
		{
			return cast Source;
		}
		else if (Std.is(Source, BitmapData) || Std.is(Source, String) || Std.is(Source, Class))
		{
			return FlxG.bitmap.add(Source);
		}
		
		return null;
	}
}