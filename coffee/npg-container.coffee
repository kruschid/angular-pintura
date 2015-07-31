module = angular.module('ngPintura', [])

# access to global paper object
module.value('ngpPaper', window.paper)

###*
# pintura container
# creates and shares paperjs scope with child directives
# creates canvas
###
module.directive 'ngpContainer', (ngpPaper) ->
  directive = 
    # directive needs its own api 
    require: 'ngpContainer'
    scope: {}
    # creates new paperjs scope and shares it with other directives
    controller: (ngpPaper) ->
      @paper = new ngpPaper.PaperScope()
    # uses the paperjs scope created by controller of same directive
    # creates canvas and appends it to current element
    link: 
      # run before children are linked so that children can use paper directly
      pre: (scope, element, attrs, ngpContainer) ->
        # create canvas
        canvas = document.createElement('canvas')
        # add as child
        element.append(canvas)
        # setup for paperjs
        ngpContainer.paper.setup(canvas)
  # returns the dirctive definition
  return directive

###*
# Pintura image
###
module.directive 'ngpImage', (ngpPaper) ->
  directive =
    require: '^ngpContainer'
    restrict: 'E'
    scope:
      src: '='
      pos: '='
      scale: '='
    link: (scope, element, attrs, ngpContainer) ->
      paper = ngpContainer.paper
      console.log paper
      circle = new paper.Path.Circle
        center: [80, 50]
        radius: 30
        strokeColor: 'black'
      console.log 'ngpImage-Directive'
 