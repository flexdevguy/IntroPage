package components
{
    import flash.display.DisplayObject;
    import flash.display.Graphics;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.geom.Point;
    import flash.ui.Keyboard;
    
    import mx.automation.IAutomationObject;
    import mx.collections.CursorBookmark;
    import mx.collections.ItemResponder;
    import mx.collections.errors.ItemPendingError ;
    import mx.controls.TileList;
    import mx.controls.listClasses.*;
    import mx.controls.scrollClasses.ScrollBar;
    import mx.core.ClassFactory;
    import mx.core.EdgeMetrics;
    import mx.core.IFlexDisplayObject ;
    import mx.core.mx_internal;
	import mx.core.UIComponentGlobals;
    import mx.events.CollectionEvent;
    import mx.events.CollectionEventKind;
    import mx.events.DragEvent;
    import mx.events.FlexEvent;
    import mx.events.ScrollEvent ;
    import mx.events.ScrollEventDetail;
    import mx.skins.halo.ListDropIndicator;
    import mx.styles.StyleManager;

    use namespace mx_internal;
    

    public class TileListExt extends mx.controls.TileList 
    {
        private var _showSelectionIndicator:Boolean = true;
        public function get showSelectionIndicator() : Boolean
        {
            return _showSelectionIndicator; 
        }

        public function set showSelectionIndicator( value : Boolean ) : void
        {
            _showSelectionIndicator = value;
            
        }
		
		private var _showHighlightIndicator:Boolean = true;
        public function get showHighlightIndicator() : Boolean
        {
            return _showHighlightIndicator; 
        }

        public function set showHighlightIndicator( value : Boolean ) : void
        {
            _showHighlightIndicator = value;
            
        }
		
		
        private var _horizontalGap : Number = 0;
        private var _verticalGap : Number = 0;
        
        public function get horizontalGap() : Number
        {
            return _horizontalGap; 
        }

        public function set horizontalGap( value : Number ) : void
        {
            _horizontalGap = isNaN( value ) ? 0 : value;
            invalidateSize();
        }


        public function get verticalGap() : Number 
        {
            return _verticalGap;
        }

        public function set verticalGap( value : Number ) : void
        {
            _verticalGap = isNaN( value ) ? 0 : value;
            invalidateSize(); 
        }
        
		public function TileListExt()
		{
			super();
		}
        /**
          *  @private
          */
        override protected function makeRowsAndColumns(
            left:Number, top:Number,
            right:Number, bottom:Number, 
            firstCol:int, firstRow:int,
            byCount:Boolean = false, rowsNeeded:uint = 0):Point
        {
            // trace(this, "makeRowsAndColumns " + left + " " + top + " " + right + " " + bottom + " " + firstCol + " " + firstRow); 
            
            var numRows:int;
            var numCols:int;
            var colNum:int;
            var rowNum:int;
            var xx:Number;
            var yy:Number;
            var data:Object; 
            var rowData:ListData;
            var uid:String
            var oldItem:IListItemRenderer 
            var item:IListItemRenderer;
            var more:Boolean;
            var valid:Boolean; 
            var i:int;
    
            var bSelected:Boolean = false;
            var bHighlight:Boolean = false;
            var bCaret:Boolean = false;
            
            if (columnWidth == 0 || rowHeight == 0) 
                return null;
                
            if (direction == TileBaseDirection.VERTICAL)
            {
                numCols = calculateNumCols();
                numRows = calculateNumRows(); 
                setRowCount(numRows);
                setColumnCount(numCols);
                colNum = firstCol;
                xx = left;
                more = (iterator != null && !iterator.afterLast && iteratorValid); 
                while (colNum < numCols)
                {
                    rowNum = firstRow;
                    yy = top;
                    while (rowNum < numRows)
                    {
                        valid = more;
                        data = more ? iterator.current : null;
                        if (iterator && more)
                        {
                            try 
                            {
                                more = iterator.moveNext();
                            }
                            catch (e1:ItemPendingError)
                            { 
                                lastSeekPending = new ListBaseSeekPending(CursorBookmark.CURRENT, 0);
                                e1.addResponder(new ItemResponder(seekPendingResultHandler, seekPendingFailureHandler, 
                                                            lastSeekPending));
                                more = false;
                                iteratorValid = false;
                            } 
                        }
    
                        if (!listItems[rowNum])
                            listItems[rowNum] = [];
    
                        if (valid && yy < bottom)
                        { 
                            uid = itemToUID(data);
                            oldItem = listItems[rowNum][colNum];
                            if (oldItem)
                            {
                                delete rowMap[ oldItem.name];
                                item = oldItem;
                            }
                            else
                            {
                                 item = itemRenderer.newInstance ();
                                item.styleName = listContent;
                            }
                            rowData = new ListData(itemToLabel(data), itemToIcon(data), labelField, uid, this, rowNum); 
                            rowMap[item.name] = rowData;
                            if (item is IDropInListItemRenderer)
                                IDropInListItemRenderer(item).listData = data ? rowData : null; 
                            if (item.data != data)
                                item.data = data;
                            if (oldItem == null)
                                listContent.addChild(DisplayObject(item)); 
                            item.visible = true;
                            if (uid)
                                visibleData[uid] = item;
                            listItems[rowNum][colNum] = item;
                            UIComponentGlobals.layoutManager.validateClient(item, true);
                            var rh:Number = item.getExplicitOrMeasuredHeight();
                            if (item.width != columnWidth || rh != (rowHeight - cachedPaddingTop - cachedPaddingBottom)) 
                                item.setActualSize(columnWidth, rowHeight - cachedPaddingTop - cachedPaddingBottom);
                            item.move(xx, yy + cachedPaddingTop);
                            bSelected = selectedData[uid] != null; 
                            bHighlight = highlightUID == uid;
                            bCaret = caretUID == uid;
                            if (uid)
                                drawItem(item, bSelected, bHighlight, bCaret); 
                        }
                        else
                        {
                            oldItem = listItems[rowNum][colNum];
                            if (oldItem)
                            { 
                                listContent.removeChild(DisplayObject(oldItem));
                                delete rowMap[oldItem.name];
                                listItems[rowNum][colNum] = null;
                            }
                        }
                        rowInfo[rowNum] = new ListRowInfo(yy, rowHeight, uid);
                        yy += rowHeight + verticalGap;
                        rowNum++; 
                    }
                    colNum ++;
                    if (firstRow)
                    {
                        // we're doing a row along the bottom so we have to skip the beginning of the next column 
                        for (i = 0; i < firstRow; i++)
                        {
                            if (iterator && more)
                            {
                                try 
                                {
                                    more = iterator.moveNext();
                                }
                                catch (e2:ItemPendingError)
                                { 
                                    lastSeekPending = new ListBaseSeekPending(CursorBookmark.CURRENT, 0);
                                    e2.addResponder(new ItemResponder(seekPendingResultHandler, seekPendingFailureHandler, 
                                                            lastSeekPending));
                                    more = false;
                                    iteratorValid = false;
                                } 
                            }
                        }
                    }
                    xx += columnWidth + horizontalGap;
                }
            }
            else // horizontal
            {
                numCols = calculateNumCols();
                numRows = calculateNumRows();
                setColumnCount(numCols);
                setRowCount(numRows);
                rowNum = firstRow; 
                yy = top;
                more = (iterator != null && !iterator.afterLast && iteratorValid);
                while (rowNum < numRows)
                {
                    colNum = firstCol; 
                    xx = left;
                    rowInfo[rowNum] = null;
                    while (colNum < numCols)
                    {
                        valid = more;
                        data = more ? iterator.current : null;
                        if (iterator && more)
                        {
                            try 
                            {
                                more = iterator.moveNext();
                            }
                            catch (e3:ItemPendingError)
                            {
                                lastSeekPending = new ListBaseSeekPending( CursorBookmark.CURRENT, 0);
                                e3.addResponder(new ItemResponder(seekPendingResultHandler, seekPendingFailureHandler, 
                                                            lastSeekPending)); 
                                more = false;
                                iteratorValid = false;
                            }
                        }
    
                        if (!listItems[rowNum]) 
                            listItems[rowNum] = [];
    
                        if (valid && xx < right)
                        {
                            uid = itemToUID(data);
                            oldItem = listItems[rowNum][colNum]; 
                            if (oldItem)
                            {
                                delete rowMap[oldItem.name];
                                item = oldItem;
                            } 
                            else
                            {
                                 item = itemRenderer.newInstance();
                                item.styleName = listContent;
                            } 
                            rowData = new ListData(itemToLabel(data), itemToIcon(data), labelField, uid, this, rowNum);
                            rowMap[item.name] = rowData;
                            if (item is IDropInListItemRenderer) 
                                IDropInListItemRenderer(item).listData = data ? rowData : null;
                            if (item.data != data)
                                item.data = data;
                            if (oldItem == null) 
                                listContent.addChild(DisplayObject(item));
                            item.visible = true;
                            if (uid)
                                visibleData[uid] = item; 
                            listItems[rowNum][colNum] = item;
                            UIComponentGlobals.layoutManager.validateClient(item, true);
                            var rh1:Number = item.getExplicitOrMeasuredHeight(); 
                            if (item.width != columnWidth || rh1 != (rowHeight - cachedPaddingTop - cachedPaddingBottom))
                                item.setActualSize(columnWidth, rowHeight - cachedPaddingTop - cachedPaddingBottom); 
                            item.move(xx, yy + cachedPaddingTop);
                            bSelected = selectedData[uid] != null;
                            bHighlight = highlightUID == uid;
                            bCaret = caretUID == uid; 
                            if (!rowInfo[rowNum])
                                rowInfo[rowNum] = new ListRowInfo(yy, rowHeight, uid);
                            if (uid)
                                drawItem(item, bSelected, bHighlight, bCaret); 
                        }
                        else
                        {
                            if (!rowInfo[rowNum])
                                rowInfo[rowNum] = new ListRowInfo(yy, rowHeight, uid); 
    
                            oldItem = listItems[rowNum][colNum];
                            if (oldItem)
                            {
                                listContent.removeChild(DisplayObject(oldItem)); 
                                delete rowMap[oldItem.name];
                                listItems[rowNum][colNum] = null;
                            }
                        }
                        xx += columnWidth + horizontalGap; 
                        colNum++;
                    }
                    rowNum ++;
                    if (firstCol)
                    {
                        // we're doing a column along the side so we have to skip the beginning of the next column 
                        for (i = 0; i < firstCol; i++)
                        {
                            if (iterator && more)
                            {
                                try 
                                {
                                    more = iterator.moveNext();
                                }
                                catch (e4:ItemPendingError)
                                { 
                                    lastSeekPending = new ListBaseSeekPending(CursorBookmark.CURRENT, 0)
                                    e4.addResponder(new ItemResponder(seekPendingResultHandler, seekPendingFailureHandler, 
                                                            lastSeekPending));
                                    more = false;
                                    iteratorValid = false;
                                } 
                            }
                        }
                    }
                    yy += rowHeight + verticalGap;
                }
            }
    
            if (!byCount)
            { 
                var a:Array;
                // prune excess rows and columns
                while (listItems.length > numRows)
                {
                    a = listItems.pop();
                    rowInfo.pop();
                    for (i = 0; i < a.length; i++)
                    {
                        oldItem = a[i];
                        if (oldItem)
                        {
                            listContent.removeChild(DisplayObject(oldItem));
                            delete rowMap[oldItem.name];
                        }
                    }
                }
                if (listItems.length && listItems[0].length > numCols)
                {
                    for (i = 0; i < numRows; i++)
                    {
                        a = listItems[i];
                        while ( a.length > numCols)
                        {
                            oldItem = a.pop();
                            if (oldItem)
                            {
                                listContent.removeChild (DisplayObject(oldItem));
                                delete rowMap[oldItem.name];
                            }
                        }
                    }
                }
            }
    
            return new Point(xx, yy);
        }
        
        override protected function measure() : void
        {
            super.measure();
            if( horizontalGap <= 0) return;
            
            var cc:int = (explicitColumnCount < 1) ? defaultColumnCount : explicitColumnCount;
            if( cc <= 1 ) return;
            
            var totalGapSum : Number = ( cc - 1 ) * horizontalGap 
            measuredWidth += totalGapSum;
            measuredMinWidth += totalGapSum;    
        }
        
        protected function calculateNumCols() : int
        {
            if( maxColumns > 0 ) return maxColumns; 
            return Math.max(Math.floor((listContent.width - columnWidth)/(columnWidth + horizontalGap)) + 1, 1);
        }
        
        protected function calculateNumRows() : int
        {
            if( maxRows > 0 ) return maxRows; 
            return Math.max(Math.ceil((listContent.height - rowHeight) / (rowHeight + verticalGap)) + 1, 1);
        }
		
		override protected function drawSelectionIndicator(indicator:Sprite, x:Number, y:Number, width:Number, height:Number, color:uint, itemRenderer:IListItemRenderer):void
		{
			if(!showSelectionIndicator)
				return;
			else
				super.drawSelectionIndicator(indicator, x, y, width, height, color, itemRenderer);
		}
		
		override protected function drawHighlightIndicator(indicator:Sprite, x:Number, y:Number, width:Number, height:Number, color:uint, itemRenderer:IListItemRenderer):void 
		{
            if(!showHighlightIndicator)
				return;
			else
				super.drawHighlightIndicator(indicator, x, y, width, height, color, itemRenderer);
        }
		
   
    }
}