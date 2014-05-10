package flixel.system.layer;

import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.interfaces.IFlxDestroyable;
import flixel.util.FlxDestroyUtil;
import flixel.util.loaders.CachedGraphics;
import openfl.display.Tilesheet;

class TileSheetExt extends Tilesheet implements IFlxDestroyable
{
	public static var _DRAWCALLS:Int = 0;
	
	public var cachedGraphics:CachedGraphics;
	
	public var bitmap:BitmapData;
	
	public var width:Int;
	
	public var height:Int;
	
	public var numTiles:Int = 0;
	
	public var tileOrder:Array<RectPointTileID>;
	
	public function new(cachedGraphics:CachedGraphics)
	{
		super(cachedGraphics.bitmap);
		
		this.cachedGraphics = cachedGraphics;
		bitmap = cachedGraphics.bitmap;
		width = bitmap.width;
		height = bitmap.height;
		tileOrder = new Array<RectPointTileID>();
	}
	
	public static function rebuildFromOld(old:TileSheetExt, cached:CachedGraphics):TileSheetExt
	{
		var newSheet:TileSheetExt = new TileSheetExt(cached);
		
		for (i in 0...(old.tileOrder.length))
		{
			var tileObj:RectPointTileID = old.tileOrder[i];
			newSheet.addTileRect(tileObj.rect, tileObj.point);
		}
		
		old.tileOrder = null;
		FlxDestroyUtil.destroy(old);
		
		return newSheet;
	}
	
	/**
	 * Adds new tileRect to tileSheet object
	 * @return id of added tileRect
	 */
	override public function addTileRect(rectangle:Rectangle, centerPoint:Point = null):Int 
	{
		var tileID:Int = super.addTileRect(rectangle, centerPoint);
		tileOrder[tileID] = new RectPointTileID(tileID, rectangle, centerPoint);
		return tileID;
	}
	
	public function destroy():Void
	{
		cachedGraphics = null;
		bitmap = FlxDestroyUtil.dispose(bitmap);
		
		for (rectPoint in tileOrder)
		{
			FlxDestroyUtil.destroy(rectPoint);
		}
		
		tileOrder = null;
	}
}

// TODO: rework tilesheet frame regeneration
// and remove this class completely
private class RectPointTileID implements IFlxDestroyable
{
	public var rect:Rectangle;
	public var point:Point;
	public var id:Int;
	
	public function new(id, rect, point)
	{
		this.id = id;
		this.rect = rect;
		this.point = point;
	}
	
	public function destroy():Void
	{
		rect = null;
		point = null;
	}
}
