$(function() {
  $("#friend_name").autocomplete({
    source: "/search",
		minLength: 2,
		select:
      function(event, ui) {
        $.getJSON("/friends_in?city=" + ui.item.label, function(data) {
          $("#friends_list").html("");
          $.each(data, function(i, friend) {
            $("#friends_list").append(
              "<li><a href='http://www.facebook.com/profile.php?id=" +
              friend.uid + "' target='_blank'>" + friend.name + "</a></li>");
          });
        });
        $("#friend_name").val("");
        return false;
      }
  })
});
