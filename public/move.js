(function($) {
  var offsetDiff = function(e1, e2) {
    return e2.offset().top - e1.offset().top
  }

  // Move the given element to a new position. The position is given as
  // index that points to the collection this function is called on.
  //
  // The move is visualized using a fancy animation.
  $.fn.move = function(element, targetIndex) {
    var collection = this

    var elementIndex = collection.index(element)

    if (elementIndex < 0                ||
        targetIndex == elementIndex     ||
        targetIndex == elementIndex + 1) return

    if (targetIndex > elementIndex) {
      var others      = collection.slice(elementIndex + 1, targetIndex)
      var othersDiff  = offsetDiff(others.first(), element)
      var elementDiff = offsetDiff(element, others.last())
      var place       = function() { element.insertAfter(others.last()) }
    } else {
      var others      = collection.slice(targetIndex, elementIndex)
      var othersDiff  = offsetDiff(others.last(), element)
      var elementDiff = offsetDiff(element, others.first())
      var place       = function() { element.insertBefore(others.first()) }
    }

    var origElementPosition = element.css("position")
    var origOthersPosition  = others.css("position")

    element.css({ position: "relative" })
    others.css( { position: "relative" })

    var pending  = 2
    var fireDone = function() { if (--pending <= 0) done() }

    var done = function() {
      others.css( { position: origOthersPosition,  top: "auto" })
      element.css({ position: origElementPosition, top: "auto" })
      place(element)
    }

    element.animate({ top: "+=" + elementDiff }, fireDone)
    others.animate( { top: "+=" + othersDiff  }, fireDone)
  }
})(jQuery);
