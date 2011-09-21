(function($) {
  // New idea button ------------------------------------------------------------------
  var newIdeaButton = {
    initialize: function() {
                  var me = this;

                  this.element = $("#new-idea");
                  this.element.click(function() {
                    if (me.isEnabled()) {
                      ideas.addNew();
                    }

                    return false;
                  });

                  this.enable();
                },

    isEnabled:  function() {
                  return this.element.hasClass("enabled");
                },

    isDisabled: function() {
                  return !this.isEnabled();
                },

    enable:     function() {
                  this.element.addClass("enabled");
                },

    disable:    function() {
                  this.element.removeClass("enabled");
                }
  }

  // Ideas ----------------------------------------------------------------------------
  var ideas = {
    initialize: function() {
                  this.list     = $("#ideas");
                  this.template = $("#idea-template");
                },

    add:        function(data, ready) {
                  var idea = this.template.clone();

                  idea.removeAttr("id");
                  idea.appendTo(this.list);

                  this._makeEditable(idea);
                  this._makeDraggable(idea);

                  if (data["text"]) idea.find(".text").text(data["text"]);
                  if (data["id"])   idea.attr("id", "idea-" + data["id"]);

                  if (typeof(ready) == "function") {
                    var callback = function() { ready(idea); }
                  } else {
                    var callback = function() {}
                  }

                  idea.slideDown(200, callback);
                },

    addNew:     function() {
                  newIdeaButton.disable();

                  this.add({}, function(idea) {
                    var text = idea.find(".text");

                    text.click();
                    text.find("textarea").select();

                    var distance = idea.offset().top;
                    $(document).scrollTop(distance);
                  });
                },

    trash:      function(idea, effect) {
                  // TODO: actally trash the idea.
                  var callback = function() { idea.remove(); };

                  if (effect == "fade") {
                    idea.fadeOut(200, callback);
                  } else {
                    idea.slideUp(200, callback);
                  }
                },

    isNew:      function(idea) {
                  return idea.attr("id") == undefined;
                },

    load:       function() {
                  var me = this;

                  $.getJSON("/ideas", function(data) {
                    data.forEach(function(datum) {
                      me.add(datum);
                    });
                  });
                },

    // privates

    _makeEditable:  function(idea) {
                      var me = this;

                      var url = "/ideas";
                      var method = "POST";

                      idea.find(".text").editable(url, {
                        cancel:   "Cancel",
                        method:   method,
                        submit:   "Save",
                        tooltip:  "Click to edit.",
                        type:     "textarea",

                        callback: function() {
                                    newIdeaButton.enable();
                                  },

                        onreset:  function() {
                                    if (me.isNew(idea)) {
                                      me.trash(idea, "slide");
                                      newIdeaButton.enable();
                                    }
                                  }
                      });
                    },

    _makeDraggable: function(idea) {
                      idea.draggable({
                        opacity:  0.5,
                        revert:   "invalid"
                      });
                    },

  }

  // Trash ----------------------------------------------------------------------------
  var trash = {
    initialize: function() {
                  this.element = $("#trash");
                  this.element.droppable({
                    tolerance:  "touch",
                    over:       function() { $(this).addClass("active"); },
                    out:        function() { $(this).removeClass("active"); },

                    drop:       function(event, ui) {
                                  ideas.trash(ui.draggable, "fade");
                                  $(this).removeClass("active");
                                }
                  });
                }
  }

  $(document).ready(function() {
    newIdeaButton.initialize();
    ideas.initialize();
    trash.initialize();

    ideas.load();
  });
})(jQuery);
