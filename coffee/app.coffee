app = angular.module('app', ['ngPintura'])

app.controller 'PinturaCtrl', ($scope) ->
  $scope.image =
    src: 'images/img1.jpg' 
    position: 
      x: -137.5
      y: -68
    scaling: 2
    maxScaling: 5
    scaleStep: 0.11
    mwScaleStep: 0.09
    moveStep: 99
    fitOnload: true
    progress: 0

  $scope.setURLSource1 = ->
    $scope.image.src = 'images/img1.jpg'

  $scope.setURLSource2 = ->
    $scope.image.src = 'images/img2.jpg'

  $scope.setObjectSource = ->
    $scope.image.src = undefined # hides image and show indicator
    img = new Image()
    img.onload = -> 
      $scope.$apply -> $scope.image.src = img
    img.src = 'images/img3.jpg'

  $scope.setSmallImage = ->
    $scope.image.src = 'images/trier.png'

  $scope.setCollage = ->
    $scope.image.src = [
      url: 'images/collage1.jpg'
      x: 0
      y: 0
    ,
      url: 'images/collage2.jpg'
      x: 1
      y: 0
    ]


      