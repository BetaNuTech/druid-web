$(document).on("turbolinks:load", function(){
  window.slide_nav = new SlideNav();
});

class SlideNav {
	constructor() {
		this.sidebar = $('#sidebar');
    if (this.sidebar[0] == undefined) { return(false) }
		this.visible = false;
		this.hamburger_id = '#nav-hamburger';
		this.toggle_button = $(this.hamburger_id);
		this.init_slide_nav();
		this.init_behaviors();
	}

	init_behaviors() {
		var that = this;
		this.toggle_button.on('click', that.handle_button_click.bind(that));
    this.handle_window_resize();
    this.handle_content_click();
		return(true);
	}

	display() {
		this.visible = true;
		$(this.element).show("slide", { direction: "left" }, 500);
		return(true);
	}

	hide () {
		this.visible = false;
		$(this.element).hide("slide", { direction: "left" }, 200);
		return(true);
	}

	init_slide_nav () {
		this.element = this.sidebar[0].cloneNode(true);
		$( this.element ).css({
			position: 'fixed',
			top: '0px',
			left: '0px',
			display: 'none',
			background: 'white',
			width: '200px',
			'z-index': '1000',
      'border-right': '2px solid #F0F0F0',
      // 'box-shadow': '5px 5px 10px #ccc'
		})
		document.getElementById('content').appendChild(this.element);
	}

	handle_button_click () {
		if (this.visible) {
			this.hide();
		} else {
			this.display();
		}
	}

	handle_window_resize () {
		var that = this;
		window.onresize = function() { if (that.visible) { that.hide() } }
		return(true);
  }

  handle_content_click () {
    var that = this;
    $('#viewcontent').on('click', function(){ that.hide() })
  }

}
