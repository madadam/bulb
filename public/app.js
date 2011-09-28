(function($) {

  $.fn.shrink = function(duration, callback) {
    return this.animate({ marginTop:  (this.outerHeight() / 2) + "px",
                          marginLeft: (this.outerWidth() / 2) + "px",
                          width:      0,
                          height:     0,
                          opacity:    0},
                        duration,
                        callback);
  }


  // New idea button ------------------------------------------------------------------
  var newIdeaButton = {
    initialize: function() {
                  var me = this

                  this.element = $("#new-idea")
                  this.element.click(function() {
                    if (me.isEnabled()) {
                      ideas.addNew()
                    }

                    return false
                  })

                  this.enable()
                },

    isEnabled:  function() {
                  return this.element.hasClass("enabled")
                },

    isDisabled: function() {
                  return !this.isEnabled()
                },

    enable:     function() {
                  this.element.addClass("enabled")
                },

    disable:    function() {
                  this.element.removeClass("enabled")
                }
  }

  // Ideas ----------------------------------------------------------------------------
  var ideas = {
    initialize:   function() {
                    this.list     = $("#ideas")
                    this.template = $("#idea-template")
                  },

    add:          function(data, ready) {
                    var idea = this.template.clone()

                    idea.removeAttr("id")
                    idea.appendTo(this.list)

                    if (data["text"]) {
                      idea.find(".text").text(data["text"])
                    }

                    if (data["id"]) {
                      idea.attr("id", "idea-" + data["id"])
                    }

                    if (data["timestamp"]) {
                      idea.attr("data-timestamp", data["timestamp"])
                    }

                    this.setVotes(idea, data["votes"] || 0);

                    this._makeEditable(idea)
                    this._makeDraggable(idea)
                    this._makeVotable(idea)

                    if (typeof(ready) == "function") {
                      var callback = function() { ready(idea) }
                    } else {
                      var callback = function() {}
                    }

                    idea.slideDown(200, callback)
                  },

    addNew:       function() {
                    newIdeaButton.disable()

                    this.add({}, function(idea) {
                      var text = idea.find(".text")

                      text.click()
                      text.find("textarea").select()

                      var distance = idea.offset().top
                      $(document).scrollTop(distance)
                    })
                  },

    startVote:    function(idea, way) {
                    var me = this
                    var id = this.getId(idea)
                    if (id == undefined) return

                    $.post("/ideas/" + id + "/" + way)
                  },

    finishVote:   function(id, votes) {
                    var idea = this.find(id)

                    this.setVotes(idea, votes)
                    this.sort(idea)
                  },


    startDelete:  function(idea) {
                    $.ajax("/ideas/" + this.getId(idea), { type: "DELETE" })
                  },

    finishDelete: function(id) {
                    var idea = this.find(id)
                    if (idea.length <= 0) return

                    this.remove(idea, "shrink")
                  },

    remove:       function(idea, effect) {
                    var callback = function() { idea.remove() }

                    if (effect == "shrink") {
                      idea.shrink(200, callback)
                    } else {
                      idea.slideUp(200, callback)
                    }
                  },

    finishUpdate: function(id, text) {
                    this.find(id).find(".text").text(text)
                  },

    isNew:        function(idea) {
                    return idea.attr("id") == undefined
                  },

    getId:        function(idea) {
                    var id = idea.attr("id")

                    if (id) {
                      return id.slice("idea-".length)
                    } else {
                      return undefined
                    }
                  },

    setVotes:     function(idea, votes) {
                    idea.attr("data-votes", votes)
                    idea.find(".votes").text(votes)
                  },

    load:         function() {
                    var me = this

                    $.getJSON("/ideas", function(data) {
                      data.forEach(function(datum) {
                        me.add(datum)
                      })
                    })
                  },

    all:          function() {
                    return this.list.find("li").not(this.template);
                  },

    find:         function(id) {
                    return $("#idea-" + id)
                  },

    filter:       function(query) {
                    this.all().each(function() {
                      var idea = $(this)
                      var text = idea.find('.text').text()

                      if (text.toLowerCase().indexOf(query.toLowerCase()) > -1) {
                        idea.show()
                      } else {
                        idea.hide()
                      }
                    })
                  },

    sort:         function(idea) {
                    var all   = this.all()
                    var index = this._findIndexToInsert(all, idea)

                    all.move(idea, index)
                  },

    isLess:       function(a, b) {
                    var aVotes = parseInt(a.attr("data-votes"))
                    var bVotes = parseInt(b.attr("data-votes"))

                    if (aVotes == bVotes) {
                      var aTimestamp = parseInt(a.attr("data-timestamp"))
                      var bTimestamp = parseInt(b.attr("data-timestamp"))

                      return aTimestamp < bTimestamp
                    } else {
                      return aVotes > bVotes
                    }
                  },

    // privates

    _findIndexToInsert: function(all, idea) {
                          var result = all.length
                          var me = this

                          all.each(function(index) {
                            if (me.isLess(idea, $(this))) {
                              result = index
                              return false
                            }
                            return true
                          })

                          return result
                        },

    _makeEditable:  function(idea) {
                      var me = this

                      var callback = function(value, settings) {
                        if (me.isNew(idea)) {
                          var method = "POST"
                          var url    = "/ideas"
                        } else {
                          var method = "PUT"
                          var url    = "/ideas/" + me.getId(idea)
                        }

                        $.ajax(url, {
                          type:     method,
                          data:     {value: value},
                          complete: function() { newIdeaButton.enable() },
                          success:  function(data) {
                                      idea.attr("id", "idea-" + data["id"])
                                    }
                        })

                        return value
                      }

                      idea.find(".text").editable(callback, {
                        cancel:   "Cancel",
                        submit:   "Save",
                        tooltip:  "Click to edit.",
                        type:     "textarea",

                        onreset:  function() {
                                    if (me.isNew(idea)) {
                                      me.remove(idea, "slide")
                                      newIdeaButton.enable()
                                    }
                                  }
                      })
                    },

    _makeDraggable: function(idea) {
                      idea.draggable({
                        opacity:  0.5,
                        revert:   "invalid",
                        scroll:   false,
                        handle:   ".handle"
                      })
                    },

    _makeVotable:   function(idea) {
                      var me = this

                      idea.find('a.up').click(function() {
                        me.startVote(idea, "up")
                        return false
                      })

                      idea.find('a.down').click(function() {
                        me.startVote(idea, "down")
                        return false
                      })
                    }

  }

  // Trash ----------------------------------------------------------------------------
  var trash = {
    initialize: function() {
                  this.element = $("#trash")
                  this.element.droppable({
                    tolerance:  "touch",
                    over:       function() { $(this).addClass("active") },
                    out:        function() { $(this).removeClass("active") },

                    drop:       function(event, ui) {
                                  ideas.startDelete(ui.draggable, "shrink")
                                  $(this).removeClass("active")
                                }
                  })
                }
  }

  // Indicator ------------------------------------------------------------------------
  var indicator = {
    initialize: function() {
                  this.element = $("#indicator")
                  this.element.ajaxStart(function() { $(this).show() })
                  this.element.ajaxStop(function()  { $(this).hide() })

                  this.element.ajaxError(function(event, request) {
                    alert(request.responseText)
                  })
                }
  }

  // Search ---------------------------------------------------------------------------
  var search = {
    initialize: function() {
                  var me = this

                  this.element = $("#search")
                  this.element.keyup(function() {
                    ideas.filter(me.element.val())
                  })
                },

  }

  $(document).ready(function() {
    ideas.initialize()
    indicator.initialize()
    newIdeaButton.initialize()
    search.initialize()
    trash.initialize()

    ideas.load()

    var host      = document.location.hostname
    var protocol  = document.location.protocol.replace(/http(s?):/, "ws$1:")
    var port      = $("body").attr("data-web-socket-port")
    var socketUrl = protocol + "//" + host + ":" + port
    var socket    = new WebSocket(socketUrl)

    socket.onmessage = function(message) {
      var data    = JSON.parse(message.data)
      var action  = data.action
      var payload = data.payload

      switch (action) {
        case 'ideas/create':
          ideas.add(payload, function() {})
          break
        case 'ideas/delete':
          ideas.finishDelete(payload["id"], "shrink")
          break
        case 'ideas/vote':
          ideas.finishVote(payload["id"], payload["votes"])
          break
        case 'ideas/update':
          ideas.finishUpdate(payload["id"], payload["text"])
          break
      }
    }
  })
})(jQuery)
