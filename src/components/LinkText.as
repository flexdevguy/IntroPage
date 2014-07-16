package components
{
	import flash.events.MouseEvent;
	
	import mx.controls.Text;
	
	public class LinkText extends Text
	{
		private var _link:Boolean = true;
		public function get link():Boolean
		{
			return _link;
		}
		public function set link(value:Boolean):void
		{
			if(_link == value) return;
			
			_link = value;
			
			if(value)
				initLinkSetup();
			else
				revokeLinkSetup();
		}
		public function LinkText()
		{
			super();
			initLinkSetup();	
		}
		private function initLinkSetup():void
		{
			addEventListener(MouseEvent.MOUSE_OVER,onMouseRollHandler,false,0,true);
			addEventListener(MouseEvent.MOUSE_OUT,onMouseRollHandler,false,0,true);
			this.styleName="lblLinkNormal";
			buttonMode=true;
			useHandCursor=true;
			mouseChildren=false;
		}
		
		private function revokeLinkSetup():void
		{
			removeEventListener(MouseEvent.MOUSE_OVER,onMouseRollHandler);
			removeEventListener(MouseEvent.MOUSE_OUT,onMouseRollHandler);
			this.styleName="lblLinkNormal";
			buttonMode=false;
			useHandCursor=false;
			mouseChildren=false;
		}
		private function onMouseRollHandler(event:MouseEvent):void
		{
			if (event.type == MouseEvent.MOUSE_OVER)
			{
				this.styleName="lblLinkOver";
			}
			else
			{
				this.styleName="lblLinkNormal";
			}
			
		}
	}
}