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
                      var idea = ideas.addEmpty(ideas.edit)
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
                    var idea = this.find(data["id"]) || this.addEmpty()

                    if (data["text"]) {
                      idea.find(".text").text(data["text"])
                    }

                    if (data["timestamp"]) {
                      idea.attr("data-timestamp", data["timestamp"])
                    }

                    if (idea.attr("id") == undefined && data["id"]) {
                      idea.attr("id", "idea-" + data["id"])
                    }

                    this.makeDraggable(idea)
                    this.makeVotable(idea)

                    this.setVotes(idea, data["votes"])
                    this.setMyVote(idea, data["my_vote"])
                  },

    addEmpty:     function(ready) {
                    if (ready == undefined) ready = function() {}

                    var idea = this.template.clone()

                    idea.removeAttr("id")
                    idea.appendTo(this.list)
                    this.makeEditable(idea)
                    idea.slideDown(200, function() { ready(idea) })

                    return idea
                  },

    edit:         function(idea) {
                    var text = idea.find(".text")

                    text.click()
                    text.find("textarea").select()

                    var distance = idea.offset().top
                    $(document).scrollTop(distance)
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

    startVote:    function(idea, action) {
                    var me = this
                    var id = this.getId(idea)
                    if (id == undefined) return

                    $.post("/ideas/" + id + "/toggle-" + action)
                  },

    finishVote:   function(id, votes, myVote) {
                    var idea = this.find(id)

                    this.setVotes(idea, votes)
                    this.setMyVote(idea, myVote)
                    this.sort(idea)
                  },


    setVotes:     function(idea, votes) {
                    idea.find(".votes").text(votes || 0)
                  },

    setMyVote:    function(idea, myVote) {
                    idea.removeClass("upvote downvote")
                    if (myVote) { idea.addClass(myVote) }
                  },

    getVotes:     function(idea) {
                    return parseInt(idea.find(".votes").text())
                  },

    makeVotable:  function(idea) {
                    if (idea.hasClass("votable")) return
                    idea.addClass("votable")

                    var me = this

                    idea.find("a.up").click(function() {
                      me.startVote(idea, "upvote")
                      return false
                    })

                    idea.find("a.down").click(function() {
                      me.startVote(idea, "downvote")
                      return false
                    })
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
                    var result = $("#idea-" + id)
                    return result.length > 0 ? result : null
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
                    var index = this.findIndexToInsert(all, idea)

                    all.move(idea, index)
                  },

    isLess:       function(a, b) {
                    var aVotes = this.getVotes(a)
                    var bVotes = this.getVotes(b)

                    if (aVotes == bVotes) {
                      var aTimestamp = parseInt(a.attr("data-timestamp"))
                      var bTimestamp = parseInt(b.attr("data-timestamp"))

                      return aTimestamp < bTimestamp
                    } else {
                      return aVotes > bVotes
                    }
                  },

    findIndexToInsert: function(all, idea) {
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

    makeEditable:  function(idea) {
                     var me = this

                     var send = function(id, value) {
                       $.ajax("/ideas/" + id, {
                         type:     "PUT",
                         data:     {value: value},
                         complete: function() { newIdeaButton.enable() }
                       })
                     }

                     var callback = function(value, settings) {
                       if (me.isNew(idea)) {
                         $.post("/ideas/next-id", function(data) {
                           idea.attr("id", "idea-" + data["id"])
                           send(data["id"], value)
                         })
                       } else {
                         send(me.getId(idea), value)
                       }

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

    makeDraggable: function(idea) {
                     idea.draggable({
                       opacity:  0.5,
                       revert:   "invalid",
                       scroll:   false,
                       handle:   ".handle"
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
                    alert(request.statusText)
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
                }
  }

  var initializeSocket = function() {
    if (!window.WebSocket) {
      if (window.MozWebSocket) {
        window.WebSocket = window.MozWebSocket
      } else {
        $("body").empty().html("<p class=\"fail\">This browser does not support WebSockets and that sucks.</p>")
        return
      }
    }

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
        case 'ideas/put':
          ideas.add(payload)
          break
        case 'ideas/delete':
          ideas.finishDelete(payload["id"], "shrink")
          break
        case 'ideas/vote':
          ideas.finishVote(payload["id"], payload["votes"], payload["my_vote"])
          break
      }
    }
  }

  $(document).ready(function() {
    ideas.initialize()
    indicator.initialize()
    newIdeaButton.initialize()
    search.initialize()
    trash.initialize()

    ideas.load()

    initializeSocket();
  })
})(jQuery)
