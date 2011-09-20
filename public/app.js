(function($) {
  $(document).ready(function() {
    var prepareItem = function(item) {
      item.find(".text").editable("/", {type: "textarea"});
      item.draggable();
    }

    $("#ideas li").each(function() { prepareItem($(this)); });

    // Add new idea.
    $("#new-idea").click(function() {
      var list = $("#ideas");
      var item = $("<li>");
      var text = $("<div>").addClass("text").text("Put your idea here.");

      item.append(text);
      item.hide();
      prepareItem(item);

      list.append(item);

      item.slideDown(function() {
        text.click();
        text.find("textarea").select();
        $.scrollTo(text);
      });
    });

    // Trash.
    $("#trash").droppable({
      tolerance: "touch",
      over: function() { $(this).addClass("active"); },
      out: function() { $(this).removeClass("active"); },

      drop: function(event, ui) {
        var idea  = ui.draggable;
        var trash = $(this);

        // TODO: actally trash the idea.

        idea.fadeOut(200, function() {
          idea.remove();
          trash.removeClass("active");
        });
      }
    });
  });
})(jQuery);
