package flixel.system.layer;

import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.interfaces.IFlxDestroyable;
import flixel.util.FlxDestroyUtil;
import openfl.display.Tilesheet;

class TileSheetExt extends Tilesheet implements IFlxDestroyable
{
	public static var _DRAWCALLS:Int = 0;
	
	public var tileOrder:Array<Rectangle>;
	
	public function new(bitmap:BitmapData)
	{
		super(bitmap);
		tileOrder = new Array<Rectangle>();
	}
	
	public static function rebuildFromOld(old:TileSheetExt, bitmap:BitmapData):TileSheetExt
	{
		var newSheet:TileSheetExt = new TileSheetExt(bitmap);
		
		for (i in 0...(old.tileOrder.length))
		{
			newSheet.addTileRect(old.tileOrder[i]);
		}
		
		FlxDestroyUtil.destroy(old);
		return newSheet;
	}
	
	/**
	 * Adds new tileRect to tileSheet object
	 * @return id of added tileRect
	 */
	override public function addTileRect(rectangle:Rectangle, centerPoint:Point = null):Int 
	{
		var tileID:Int = super.addTileRect(rectangle);
		tileOrder[tileID] = rectangle;
		return tileID;
	}
	
	public function destroy():Void
	{
		tileOrder = null;
	}
}