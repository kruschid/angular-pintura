app = angular.module('app', ['ngPintura'])

app.controller 'PinturaCtrl', ($scope) ->
  $scope.image =
    src: 'images/panorama.jpg' 
    position: 
      x: -137.5
      y: -68
    scale: 2
#   $scope.selection =
#     position:
#       x: 100
#       y: 50
#     size:
#       width: 200
#       height: 100