app = angular.module('app', ['ngPintura'])

app.controller 'PinturaCtrl', ($scope) ->
  $scope.image =
    src: 'images/panorama.jpg' 
    position: 
      x: -200
      y: 0
    scale: 1
#   $scope.selection =
#     position:
#       x: 100
#       y: 50
#     size:
#       width: 200
#       height: 100