module = angular.module('ngPintura', [])

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