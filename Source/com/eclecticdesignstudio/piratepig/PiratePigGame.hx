package com.eclecticdesignstudio.piratepig;


import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Loader;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.BlurFilter;
import flash.filters.DropShadowFilter;
import flash.geom.Point;
import flash.media.Sound;
import flash.net.URLRequest;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.Lib;
import motion.Actuate;
import motion.easing.Quad;

@:bitmap("images/game_bear.png") class BearImage extends BitmapData {}
@:bitmap("images/game_bunny_02.png") class BunnyImage extends BitmapData {}
@:bitmap("images/game_carrot.png") class CarrotImage extends BitmapData {}
@:bitmap("images/game_lemon.png") class LemonImage extends BitmapData {}
@:bitmap("images/game_panda.png") class PandaImage extends BitmapData {}
@:bitmap("images/game_piratePig.png") class PiratePigImage extends BitmapData {}
class PiratePigImage2 extends BitmapData {}
@:sound("sounds/3.wav") class Sound3Data extends Sound {}
@:sound("sounds/4.wav") class Sound4Data extends Sound {}
@:sound("sounds/5.wav") class Sound5Data extends Sound {}


class PiratePigGame extends Sprite {
	
	
	private static var NUM_COLUMNS:Int = 8;
	private static var NUM_ROWS:Int = 8;
	
	private static var tileBitmapData:Array <BitmapData> = [];
	
	private var Background:Sprite;
	private var IntroSound:Sound;
	private var Logo:Loader;
	private var Score:TextField;
	private var Sound3:Sound;
	private var Sound4:Sound;
	private var Sound5:Sound;
	private var TileContainer:Sprite;
	
	public var currentScale:Float;
	public var currentScore:Int;
	
	private var cacheMouse:Point;
	private var needToCheckMatches:Bool;
	private var selectedTile:Tile;
	private var tiles:Array <Array <Tile>>;
	
	
	public function new () {
		
		super ();
		
		initialize ();
		construct ();
		
	}
	
	
	private function addTile (row:Int, column:Int, animate:Bool = true):Void {
		
		var type = Math.round (Math.random () * (tileBitmapData.length - 1));
		var tile = new Tile (tileBitmapData[type]);
		
		tile.type = type;
		tile.row = row;
		tile.column = column;
		tiles[row][column] = tile;
		
		var position = getPosition (row, column);
		
		if (animate) {
			
			var firstPosition = getPosition (-1, column);
			
			#if !js
			tile.alpha = 0;
			#end
			tile.x = firstPosition.x;
			tile.y = firstPosition.y;
			
			tile.moveTo (0.15 * (row + 1), position.x, position.y);
			#if !js
			Actuate.tween (tile, 0.3, { alpha: 1 } ).delay (0.15 * (row - 2)).ease (Quad.easeOut);
			#end
			
		} else {
			
			tile.x = position.x;
			tile.y = position.y;
			
		}
		
		TileContainer.addChild (tile);
		needToCheckMatches = true;
		
	}
	
	
	private function construct ():Void {
		
		addChild (Logo);
		
		//var font:Dynamic = null;
		//var font = Assets.getFont ("fonts/FreebooterUpdated.ttf");
		//var defaultFormat = new TextFormat (font.fontName, 60, 0x000000);
		var defaultFormat = new TextFormat ("_sans", 60, 0x000000);
		defaultFormat.align = TextFormatAlign.RIGHT;
		
		#if js
		// Right-aligned text is not supported in HTML5 yet
		defaultFormat.align = TextFormatAlign.LEFT;
		#end
		
		var contentWidth = 75 * NUM_COLUMNS;
		
		Score.x = contentWidth - 200;
		Score.width = 200;
		Score.y = 12;
		Score.selectable = false;
		Score.defaultTextFormat = defaultFormat;
		
		#if !js
		Score.filters = [ new BlurFilter (1.5, 1.5), new DropShadowFilter (1, 45, 0, 0.2, 5, 5) ];
		#else
		Score.y = 0;
		Score.x += 90;
		#end
		
		//Score.embedFonts = true;
		addChild (Score);
		
		Background.y = 85;
		Background.graphics.beginFill (0xFFFFFF, 0.4);
		Background.graphics.drawRect (0, 0, contentWidth, 75 * NUM_ROWS);
		
		#if !js
		Background.filters = [ new BlurFilter (10, 10) ];
		addChild (Background);
		#end
		
		TileContainer.x = 14;
		TileContainer.y = Background.y + 14;
		TileContainer.addEventListener (MouseEvent.MOUSE_DOWN, TileContainer_onMouseDown);
		Lib.current.stage.addEventListener (MouseEvent.MOUSE_UP, stage_onMouseUp);
		addChild (TileContainer);
		
		IntroSound = new Sound (new URLRequest ("sounds/theme.mp3"));
		Sound3 = new Sound3Data ();
		Sound4 = new Sound4Data ();
		Sound5 = new Sound5Data ();
		
		newGame ();
		
	}
	
	
	private function dropTiles ():Void {
		
		for (column in 0...NUM_COLUMNS) {
			
			var spaces = 0;
			
			for (row in 0...NUM_ROWS) {
				
				var index = (NUM_ROWS - 1) - row;
				var tile = tiles[index][column];
				
				if (tile == null) {
					
					spaces++;
					
				} else {
					
					if (spaces > 0) {
						
						var position = getPosition (index + spaces, column);
						tile.moveTo (0.15 * spaces, position.x,position.y);
						
						tile.row = index + spaces;
						tiles[index + spaces][column] = tile;
						tiles[index][column] = null;
						
						needToCheckMatches = true;
						
					}
					
				}
				
			}
			
			for (i in 0...spaces) {
				
				var row = (spaces - 1) - i;
				addTile (row, column);
				
			}
			
		}
		
	}
	
	
	private function findMatches (byRow:Bool, accumulateScore:Bool = true):Array <Tile> {
		
		var matchedTiles = new Array <Tile> ();
		
		var max:Int;
		var secondMax:Int;
		
		if (byRow) {
			
			max = NUM_ROWS;
			secondMax = NUM_COLUMNS;
			
		} else {
			
			max = NUM_COLUMNS;
			secondMax = NUM_ROWS;
			
		}
		
		for (index in 0...max) {
			
			var matches = 0;
			var foundTiles = new Array <Tile> ();
			var previousType = -1;
			
			for (secondIndex in 0...secondMax) {
				
				var tile:Tile;
				
				if (byRow) {
					
					tile = tiles[index][secondIndex];
					
				} else {
					
					tile = tiles[secondIndex][index];
					
				}
				
				if (tile != null && !tile.moving) {
					
					if (previousType == -1) {
						
						previousType = tile.type;
						foundTiles.push (tile);
						continue;
						
					} else if (tile.type == previousType) {
						
						foundTiles.push (tile);
						matches++;
						
					}
					
				}
				
				if (tile == null || tile.moving || tile.type != previousType || secondIndex == secondMax - 1) {
					
					if (matches >= 2 && previousType != -1) {
						
						if (accumulateScore) {
							
							if (matches > 3) {
								
								Sound5.play ();
								
							} else if (matches > 2) {
								
								Sound4.play ();
								
							} else {
								
								Sound3.play ();
								
							}
							
							currentScore += Std.int (Math.pow (matches, 2) * 50);
							
						}
						
						matchedTiles = matchedTiles.concat (foundTiles);
						
					}
					
					matches = 0;
					foundTiles = new Array <Tile> ();
					
					if (tile == null || tile.moving) {
						
						needToCheckMatches = true;
						previousType = -1;
						
					} else {
						
						previousType = tile.type;
						foundTiles.push (tile);
						
					}
					
				}
				
			}
			
		}
		
		return matchedTiles;
		
	}
	
	
	private function getPosition (row:Int, column:Int):Point {
		
		return new Point (column * (57 + 16), row * (57 + 16));
		
	}
	
	
	private function initialize ():Void {
		
		tileBitmapData = [ new BearImage (0, 0), new BunnyImage (0, 0), new CarrotImage (0, 0), new LemonImage (0, 0), new PandaImage (0, 0), new PiratePigImage (0, 0) ];
		
		currentScale = 1;
		currentScore = 0;
		
		tiles = new Array <Array <Tile>> ();
		
		for (row in 0...NUM_ROWS) {
			
			tiles[row] = new Array <Tile> ();
			
			for (column in 0...NUM_COLUMNS) {
				
				tiles[row][column] = null;
				
			}
			
		}
		
		Background = new Sprite ();
		Logo = new Loader ();
		Logo.load (new URLRequest ("images/logo.png"));
		Score = new TextField ();
		TileContainer = new Sprite ();
		
	}
	
	
	public function newGame ():Void {
		
		currentScore = 0;
		Score.text = "0";
		
		for (row in 0...NUM_ROWS) {
			
			for (column in 0...NUM_COLUMNS) {
				
				removeTile (row, column, false);
				
			}
			
		}
		
		for (row in 0...NUM_ROWS) {
			
			for (column in 0...NUM_COLUMNS) {
				
				addTile (row, column, false);
				
			}
			
		}
		
		IntroSound.play ();
		
		removeEventListener (Event.ENTER_FRAME, this_onEnterFrame);
		addEventListener (Event.ENTER_FRAME, this_onEnterFrame);
		
	}
	
	
	public function removeTile (row:Int, column:Int, animate:Bool = true):Void {
		
		var tile = tiles[row][column];
		
		if (tile != null) {
			
			tile.remove (animate);
			
		}
		
		tiles[row][column] = null;
		
	}
	
	
	public function resize (newWidth:Int, newHeight:Int):Void {
		
		var maxWidth = newWidth * 0.90;
		var maxHeight = newHeight * 0.86;
		
		currentScale = 1;
		scaleX = 1;
		scaleY = 1;
		
		#if js
		
		// looking up the total width and height is not working, so we'll calculate it ourselves
		
		var currentWidth = 75 * NUM_COLUMNS;
		var currentHeight = 75 * NUM_ROWS + 85;
		
		#else
		
		var currentWidth = width;
		var currentHeight = height;
		
		#end
		
		if (currentWidth > maxWidth || currentHeight > maxHeight) {
			
			var maxScaleX = maxWidth / currentWidth;
			var maxScaleY = maxHeight / currentHeight;
			
			if (maxScaleX < maxScaleY) {
				
				currentScale = maxScaleX;
				
			} else {
				
				currentScale = maxScaleY;
				
			}
			
			scaleX = currentScale;
			scaleY = currentScale;
			
		}
		
		x = newWidth / 2 - (currentWidth * currentScale) / 2;
		
	}
	
	
	private function swapTile (tile:Tile, targetRow:Int, targetColumn:Int):Void {
		
		if (targetColumn >= 0 && targetColumn < NUM_COLUMNS && targetRow >= 0 && targetRow < NUM_ROWS) {
			
			var targetTile = tiles[targetRow][targetColumn];
			
			if (targetTile != null && !targetTile.moving) {
				
				tiles[targetRow][targetColumn] = tile;
				tiles[tile.row][tile.column] = targetTile;
				
				if (findMatches (true, false).length > 0 || findMatches (false, false).length > 0) {
					
					targetTile.row = tile.row;
					targetTile.column = tile.column;
					tile.row = targetRow;
					tile.column = targetColumn;
					var targetTilePosition = getPosition (targetTile.row, targetTile.column);
					var tilePosition = getPosition (tile.row, tile.column);
					
					targetTile.moveTo (0.3, targetTilePosition.x, targetTilePosition.y);
					tile.moveTo (0.3, tilePosition.x, tilePosition.y);
					
					needToCheckMatches = true;
					
				} else {
					
					tiles[targetRow][targetColumn] = targetTile;
					tiles[tile.row][tile.column] = tile;
					
				}
				
			}
			
		}
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function stage_onMouseUp (event:MouseEvent):Void {
		
		if (cacheMouse != null && selectedTile != null && !selectedTile.moving) {
			
			var differenceX = event.stageX - cacheMouse.x;
			var differenceY = event.stageY - cacheMouse.y;
			
			if (Math.abs (differenceX) > 10 || Math.abs (differenceY) > 10) {
				
				var swapToRow = selectedTile.row;
				var swapToColumn = selectedTile.column;
				
				if (Math.abs (differenceX) > Math.abs (differenceY)) {
					
					if (differenceX < 0) {
						
						swapToColumn --;
						
					} else {
						
						swapToColumn ++;
						
					}
					
				} else {
					
					if (differenceY < 0) {
						
						swapToRow --;
						
					} else {
						
						swapToRow ++;
						
					}
					
				}
				
				swapTile (selectedTile, swapToRow, swapToColumn);
				
			}
			
		}
		
		selectedTile = null;
		cacheMouse = null;
		
	}
	
	
	private function this_onEnterFrame (event:Event):Void {
		
		if (needToCheckMatches) {
			
			var matchedTiles = new Array <Tile> ();
			
			matchedTiles = matchedTiles.concat (findMatches (true));
			matchedTiles = matchedTiles.concat (findMatches (false));
			
			for (tile in matchedTiles) {
				
				removeTile (tile.row, tile.column);
				
			}
			
			if (matchedTiles.length > 0) {
				
				Score.text = Std.string (currentScore);
				dropTiles ();
				
			}
			
		}
		
	}
	
	
	private function TileContainer_onMouseDown (event:MouseEvent):Void {
		
		if (Std.is (event.target, Tile)) {
			
			selectedTile = cast event.target;
			cacheMouse = new Point (event.stageX, event.stageY);
			
		} else {
			
			cacheMouse = null;
			selectedTile = null;
			
		}
		
	}
	
	
}