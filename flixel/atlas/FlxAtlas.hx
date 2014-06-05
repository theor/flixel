package flixel.atlas;

import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.AtlasFrames;
import flixel.graphics.frames.SpritesheetFrames;
import flixel.interfaces.IFlxDestroyable;
import flixel.util.FlxBitmapUtil;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxPoint;
import flixel.util.loaders.TexturePackerData;
import flixel.util.loaders.TextureAtlasFrame;
import flixel.util.loaders.TextureRegion;
import flixel.atlas.FlxNode;
import flixel.system.FlxAssets;
import flixel.system.frontEnds.BitmapFrontEnd;

// TODO: generate json file for atlas

/**
 * Class for packing multiple images in big one and generating frame data for each of them 
 * so you can easily load regions of atlas in sprites and tilemaps as a source of graphic
 */
class FlxAtlas implements IFlxDestroyable
{	
	/**
	 * Root node of atlas
	 */
	public var root:FlxNode;
	
	/**
	 * Name of this atlas, used as a key in bitmap cache
	 */
	public var name:String;
	
	public var nodes:Map<String, FlxNode>;
	
	/**
	 * BitmapData of this atlas, combines all images in big one
	 */
	public var atlasBitmapData:BitmapData;
	
	/**
	 * Offsets between nodes on x axis
	 */
	public var borderX(default, null):Int;
	/**
	 * Offsets between nodes on y axis
	 */
	public var borderY(default, null):Int;
	
	/**
	 * Total width of atlas
	 */
	public var width(default, null):Int;
	/**
	 * Total height of atlas
	 */
	public var height(default, null):Int;
	
	/**
	 * Internal storage for building atlas from queue
	 */
	private var _tempStorage:Array<TempAtlasObj>;
	
	/**
	 * Atlas constructor
	 * @param	width		atlas width
	 * @param	height		atlas height
	 * @param	borderX		horizontal distance between nodes
	 * @param	borderY		vertical distance between nodes
	 */
	public function new(name:String, width:Int, height:Int, borderX:Int = 1, borderY:Int = 1) 
	{
		nodes = new Map<String, FlxNode>();
		this.name = name;
		
		root = new FlxNode(new Rectangle(0, 0, width, height), this);
		atlasBitmapData = new BitmapData(width, height, true, FlxColor.TRANSPARENT);
		
		this.width = width;
		this.height = height;
		this.borderX = borderX;
		this.borderY = borderY;
	}
	
	/**
	 * Simply adds new node to atlas.
	 * @param	Graphic	Image to store. Could be BitmapData, String (key from OpenFl asset cache) or Class<Dynamic>.
	 * @param	Key		Image name, optional. You can ommit it if you pass String or Class<Dynamic> as Graphic source
	 * @return			Newly created and added node, or null if there is no place for it.
	 */
	public function addNode(Graphic:Dynamic, ?Key:String):FlxNode
	{
		var key:String = getKeyForGraphic(Graphic, Key);
		
		if (key == null) return null;
		
		if (hasNodeWithName(key) == true)
		{
			return nodes.get(key);
		}
		
		var data:BitmapData = getBitmapForGraphic(Graphic);
		
		if (data == null)	return null;
		
		if (root.canPlace(data.width, data.height) == false)
		{
			// There is no place for image
			return null;
		}
		
		var insertWidth:Int = (data.width == width) ? data.width : data.width + borderX;
		var insertHeight:Int = (data.height == height) ? data.height : data.height + borderY;
		
		var nodeToInsert:FlxNode = findNodeToInsert(insertWidth, insertHeight);
		if (nodeToInsert != null)
		{
			var firstChild:FlxNode;
			var secondChild:FlxNode;
			var firstGrandChild:FlxNode;
			var secondGrandChild:FlxNode;
			
			var dw:Int = nodeToInsert.width - insertWidth;
			var dh:Int = nodeToInsert.height - insertHeight;
			
			if (dw > dh) // divide horizontally
			{
				firstChild = new FlxNode(new Rectangle(nodeToInsert.x, nodeToInsert.y, insertWidth, nodeToInsert.height), this);
				secondChild = new FlxNode(new Rectangle(nodeToInsert.x + insertWidth, nodeToInsert.y, nodeToInsert.width - insertWidth, nodeToInsert.height), this);
				
				firstGrandChild = new FlxNode(new Rectangle(firstChild.x, firstChild.y, insertWidth, insertHeight), this, true, key);
				secondGrandChild = new FlxNode(new Rectangle(firstChild.x, firstChild.y + insertHeight, insertWidth, firstChild.height - insertHeight), this);
			}
			else // divide vertically
			{
				firstChild = new FlxNode(new Rectangle(nodeToInsert.x, nodeToInsert.y, nodeToInsert.width, insertHeight), this);
				secondChild = new FlxNode(new Rectangle(nodeToInsert.x, nodeToInsert.y + insertHeight, nodeToInsert.width, nodeToInsert.height - insertHeight), this);
				
				firstGrandChild = new FlxNode(new Rectangle(firstChild.x, firstChild.y, insertWidth, insertHeight), this, true, key);
				secondGrandChild = new FlxNode(new Rectangle(firstChild.x + insertWidth, firstChild.y, firstChild.width - insertWidth, insertHeight), this);
			}
			
			firstChild.left = firstGrandChild;
			firstChild.right = secondGrandChild;
			
			nodeToInsert.left = firstChild;
			nodeToInsert.right = secondChild;
			
			atlasBitmapData.copyPixels(data, data.rect, firstGrandChild.point);
			
			nodes.set(key, firstGrandChild);
			
			return firstGrandChild;
		}
		
		return null;
	}
	
	/**
	 * Generates new bitmapdata with spaces between tiles, adds this bitmapdata to this atlas, 
	 * generates SpritesheetFrames object for added node and returns it. Could be usefull for tilemaps.
	 * 
	 * @param	Graphic			Source image for node, where spaces will be inserted (could be BitmapData, String or Class<Dynamic>).
	 * @param	?Key			Optional key for image
	 * @param	frameSize		The size of tile in spritesheet
	 * @param	frameSpacing	Offsets to add in spritesheet between tiles
	 * @param	region			Region of source image to use as a source graphic
	 * @return	Generated SpritesheetFrames for added node
	 */
	public function addNodeWithSpacings(Graphic:Dynamic, ?Key:String, frameSize:Point, frameSpacing:Point, region:Rectangle = null):SpritesheetFrames
	{
		var key:String = getKeyForGraphic(Graphic, Key);
		
		if (key == null) return null;
		
		key = FlxG.bitmap.getKeyWithSpacings(key, frameSize, frameSpacing, region);
		
		if (hasNodeWithName(key) == true)
		{
			return nodes.get(key).getSpritesheetFrames(frameSize, frameSpacing);
		}
		
		var data:BitmapData = getBitmapForGraphic(Graphic);
		var nodeData:BitmapData = FlxBitmapUtil.addSpacing(data, frameSize, frameSpacing, region);
		var node:FlxNode = addNode(nodeData, key);
		
		if (node == null) return null;
		
		return node.getSpritesheetFrames(frameSize, frameSpacing);
	}
	
	// TODO: move it into BitmapFrontEnd
	/**
	 * Internal method for getting key for image
	 * 
	 * @param	Graphic	Image source to get key for. Could be BitmapData, Class<Dynamic> or String
	 * @param	?Key	Optional key. If it's not null then this string will be returned as a key
	 * @return	The key for provided graphic
	 */
	private function getKeyForGraphic(Graphic:Dynamic, ?Key:String):String
	{
		var key:String = null;
		
		if (Key != null)
		{
			return Key;
		}
		
		if (Std.is(Graphic, Class))
		{
			key = Type.getClassName(cast(Graphic, Class<Dynamic>));
		}
		else if (Std.is(Graphic, BitmapData))
		{
			// try to search in bitmap cache
			key = FlxG.bitmap.getKeyForBitmap(cast Graphic);
		}
		else if (Std.is(Graphic, String))
		{
			key = cast Graphic;
		}
		
		return key;
	}
	
	// TODO: move it into BitmapFrontEnd
	/**
	 * Internal method for resolving Graphic object to BitmapData
	 */
	private function getBitmapForGraphic(Graphic:Dynamic):BitmapData
	{
		var data:BitmapData = null;
		
		if (Std.is(Graphic, BitmapData))
		{
			data = cast Graphic;
		}
		else if (Std.is(Graphic, Class))
		{
			data = Type.createInstance(cast(Graphic, Class<Dynamic>), []).bitmapData;
		}
		else if (Std.is(Graphic, String))
		{
			data = FlxAssets.getBitmapData(Graphic);
		}
		
		return data;
	}
	
	/**
	 * Gets AtlasFrames object for this atlas.
	 * It caches graphic of this atlas and generates AtlasFrames if it is not exist yet.
	 * @return AtlasFrames for this atlas
	 */
	public function getAtlasFrames():AtlasFrames
	{
		var graphic:FlxGraphic = FlxG.bitmap.add(this.atlasBitmapData, false, name);
		
		var atlasFrames:AtlasFrames = null;
		if (graphic.atlasFrames == null)
		{
			graphic.atlasFrames = atlasFrames = new AtlasFrames(graphic);
		}
		
		var node:FlxNode;
		for (key in nodes.keys())
		{
			node = nodes.get(key);
			// if the node is filled and AtlasFrames does not contain image of the node, then we should add it
			if (node.filled && !atlasFrames.framesHash.exists(key))
			{
				var frame:Rectangle = new Rectangle(node.x, node.y, node.width - borderX, node.height - borderY);
				var sourceSize:FlxPoint = FlxPoint.get(node.width - borderX, node.height - borderY);
				var offset:FlxPoint = FlxPoint.get(0, 0);
				
				atlasFrames.addAtlasFrame(frame, sourceSize, offset, node.key, 0); 
			}
		}
		
		return graphic.atlasFrames;
	}
	
	/**
	 * Checks if atlas already contains node with the same name
	 * @param	nodeName	node name to check
	 * @return				true if atlas already contains node with the name
	 */
	public function hasNodeWithName(nodeName:String):Bool
	{
		return nodes.exists(nodeName);
	}
	
	/**
	 * Gets node by it's name
	 * @param	key		node name to search
	 * @return	node with searched name. Null if atlas doesn't contain node with a such name
	 */
	public function getNode(key:String):FlxNode
	{
		if (hasNodeWithName(key) == true)
		{
			return nodes.get(key);
		}
		
		return null;
	}
	
	/**
	 * Optimized version of method for adding multiple nodes to atlas. 
	 * Uses less atlas' area (it sorts images by the size before adding them to atlas)
	 * @param	bitmaps		BitmapData's to insert
	 * @param	keys		Names of these bitmapData's
	 * @return				true if ALL nodes were added successfully.
	 */
	public function addNodes(bitmaps:Array<BitmapData>, keys:Array<String>):Bool
	{
		var numKeys:Int = keys.length;
		var numBitmaps:Int = bitmaps.length;
		
		if (numBitmaps != numKeys)
		{
			return false;
		}
		
		var sortedBitmaps:Array<BitmapData> = bitmaps.slice(0, bitmaps.length);
		sortedBitmaps.sort(bitmapSorter);
		
		var node:FlxNode;
		var result:Bool = true;
		var index:Int;
		for (i in 0...(numBitmaps))
		{
			index = bitmaps.indexOf(sortedBitmaps[i]);
			node = addNode(sortedBitmaps[i], keys[index]);
			if (node == null)
			{
				result = false;
			}
		}
		
		return result;
	}
	
	/**
	 * Internal method for sorting bitmaps
	 */
	private function bitmapSorter(bmd1:BitmapData, bmd2:BitmapData):Int
	{
		if (bmd2.width == bmd1.width)
		{
			if (bmd2.height == bmd1.height)
			{
				return 0;
			}
			else if (bmd2.height > bmd1.height)
			{
				return 1;
			}
			else
			{
				return -1;
			}
		}
		
		if (bmd2.width > bmd1.width)
		{
			return 1;
		}
		
		return -1;
	}
	
	/**
	 * Creates new "queue" for adding new nodes.
	 * This method should be used with addToQueue() and generateFromQueue() methods:
	 * - first, you create queue, like atlas.createQueue();
	 * - second, you add several bitmaps in queue: atlas.addToQueue(bmd1, "key1").addToQueue(bmd2, "key2");
	 * - third, you actually bake those bitmaps on atlas: atlas.generateFromQueue();
	 */
	public function createQueue():FlxAtlas
	{
		if (_tempStorage != null)	_tempStorage = null;
		_tempStorage = new Array<TempAtlasObj>();
		return this;
	}
	
	/**
	 * Adds new object to queue for later creation of new node
	 * @param	data	BitmapData to bake on atlas
	 * @param	key		"name" of BitmapData. You'll use it as a key for accessing created node.
	 */
	public function addToQueue(data:BitmapData, key:String):FlxAtlas
	{
		if (_tempStorage == null)
		{
			_tempStorage = new Array<TempAtlasObj>();
		}
		
		_tempStorage.push({ bmd: data, keyStr: key });
		return this;
	}
	
	/**
	 * Adds all objects in "queue" to existing atlas. Doesn't erase any node
	 */
	public function generateFromQueue():FlxAtlas
	{
		if (_tempStorage != null)
		{
			var bitmaps:Array<BitmapData> = new Array<BitmapData>();
			var keys:Array<String> = new Array<String>();
			for (obj in _tempStorage)
			{
				bitmaps.push(obj.bmd);
				keys.push(obj.keyStr);
			}
			addNodes(bitmaps, keys);
			_tempStorage = null;
		}
		
		return this;
	}
	
	/**
	 * Destroys atlas. Use only if you want to clear memory and don't need this atlas anymore, 
	 * since it disposes atlasBitmapData and removes it from cache
	 */
	public function destroy():Void
	{
		FlxG.bitmap.remove(name);
		_tempStorage = null;
		deleteSubtree(root);
		root = null;
		atlasBitmapData = FlxDestroyUtil.dispose(atlasBitmapData);
		nodes = null;
	}
	
	/**
	 * Clears all data in atlas. Use it when you want reuse this atlas
	 */
	public function clear():Void
	{
		var rootWidth:Int = root.width;
		var rootHeight:Int = root.height;
		deleteSubtree(root);
		
		root = new FlxNode(new Rectangle(0, 0, rootWidth, rootHeight), this);
		atlasBitmapData.fillRect(root.rect, FlxColor.TRANSPARENT);
		
		var graphic:FlxGraphic = FlxG.bitmap.get(name);
		graphic.atlasFrames = FlxDestroyUtil.destroy(graphic.atlasFrames);
		nodes = new Map<String, FlxNode>();
	}
	
	private function deleteSubtree(node:FlxNode):Void
	{
		if (node != null)
		{
			if (node.left != null) deleteSubtree(node.left);
			if (node.right != null) deleteSubtree(node.right);
			node.destroy();
		}
	}
	
	// Internal iteration method
	private function findNodeToInsert(insertWidth:Int, insertHeight:Int):FlxNode
	{
		// Node stack
		var stack:Array<FlxNode> = new Array<FlxNode>();
		// Current node
		var current:FlxNode = root;
		
		var canPlaceRight:Bool = false;
		var canPlaceLeft:Bool = false;
		// Main loop
		while (true)
		{
			// Look into current node
			if (current.isEmpty && current.canPlace(insertWidth, insertHeight))
			{
				return current;
			}
			// Move to next node
			canPlaceRight = (current.right != null && current.right.canPlace(insertWidth, insertHeight));
			canPlaceLeft = (current.left != null && current.left.canPlace(insertWidth, insertHeight));
			if (canPlaceRight && canPlaceLeft)
			{
				stack.push(current.right);
				current = current.left;
			}
			else if (canPlaceLeft)
			{
				current = current.left;
			}
			else if (canPlaceRight)
			{
				current = current.right;
			}
			else
			{
				if (stack.length > 0)
				{
					// Trying to get next node from the stack
					current = stack.pop();
				}
				else
				{
					// Stack is empty. End of loop
					return null;
				}
			}
		}
		
		return null;
	}
	
	private inline function get_width():Int
	{
		return root.width;
	}
	
	private inline function get_height():Int
	{
		return root.height;
	}
}

typedef TempAtlasObj = {
	public var bmd:BitmapData;
	public var keyStr:String;
}