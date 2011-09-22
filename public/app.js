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
                  $.ajax("/ideas/" + this.getId(idea), {
                    type:     "DELETE",
                    success:  function() {
                                var callback = function() { idea.remove(); };

                                if (effect == "fade") {
                                  idea.fadeOut(200, callback);
                                } else {
                                  idea.slideUp(200, callback);
                                }
                              }
                  });
                },

    isNew:      function(idea) {
                  return idea.attr("id") == undefined;
                },

    getId:      function(idea) {
                  var id = idea.attr("id");

                  if (id) {
                    return id.slice("idea-".length);
                  } else {
                    return undefined;
                  }
                },

    load:       function() {
                  var me = this;

                  $.getJSON("/ideas", function(data) {
                    data.forEach(function(datum) {
                      me.add(datum);
                    });
                  });
                },

    filter:     function(query) {
                  this.list.find('li').not(this.template).each(function() {
                    var idea = $(this);
                    var text = idea.find('.text').text();

                    if (text.toLowerCase().indexOf(query.toLowerCase()) > -1) {
                      idea.show();
                    } else {
                      idea.hide();
                    }
                  })
                },

    // privates

    _makeEditable:  function(idea) {
                      var me = this;

                      var callback = function(value, settings) {
                        if (me.isNew(idea)) {
                          var method = "POST";
                          var url    = "/ideas";
                        } else {
                          var method = "PUT";
                          var url    = "/ideas/" + me.getId(idea);
                        }

                        $.ajax(url, {
                          type:     method,
                          data:     {value: value},
                          complete: function() { newIdeaButton.enable(); },
                          success:  function(data) {
                                      idea.attr("id", "idea-" + data["id"]);
                                    }
                        });

                        return value;
                      }

                      idea.find(".text").editable(callback, {
                        cancel:   "Cancel",
                        submit:   "Save",
                        tooltip:  "Click to edit.",
                        type:     "textarea",

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
                        revert:   "invalid",
                        scroll:   false
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

  // Indicator ------------------------------------------------------------------------
  var indicator = {
    initialize: function() {
                  this.element = $("#indicator");
                  this.element.ajaxStart(function() { $(this).show(); });
                  this.element.ajaxStop(function()  { $(this).hide(); });

                  this.element.ajaxError(function(event, request) {
                    alert(request);
                  });
                }
  }

  // Search ---------------------------------------------------------------------------
  var search = {
    initialize: function() {
                  var me = this;

                  this.element = $("#search");
                  this.element.keyup(function() {
                    ideas.filter(me.element.val());
                  });
                },

  }

  $(document).ready(function() {
    ideas.initialize();
    indicator.initialize();
    newIdeaButton.initialize();
    search.initialize();
    trash.initialize();

    ideas.load();
  });
})(jQuery);
