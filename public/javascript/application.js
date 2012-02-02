$(function() {
  $("#friend_name").autocomplete({
    source: "/search",
		select: function( event, ui ) {
						if (ui.item) {
							window.location.href = "mailto:" + ui.item.value;
						}
					}
  }).data("autocomplete")._renderItem = function(ul, item) {
    return $("<li></li>").append("<a>" + item.label + " (" + item.value + ")</a>").appendTo(ul);
  };
});
