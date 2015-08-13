(function() {
  var app;

  app = angular.module('app', ['ngPintura']);

  app.controller('PinturaCtrl', function($scope) {
    $scope.image = {
      src: 'images/img1.jpg',
      position: {
        x: -137.5,
        y: -68
      },
      scaling: 2,
      maxScaling: 5,
      scaleStep: 0.11,
      mwScaleStep: 0.09,
      moveStep: 99,
      fitOnload: true
    };
    $scope.setURLSource1 = function() {
      return $scope.image.src = 'images/img1.jpg';
    };
    $scope.setURLSource2 = function() {
      return $scope.image.src = 'images/img2.jpg';
    };
    $scope.setObjectSource = function() {
      var img;
      $scope.image.src = void 0;
      img = new Image();
      img.onload = function() {
        return $scope.$apply(function() {
          return $scope.image.src = img;
        });
      };
      return img.src = 'images/img3.jpg';
    };
    return $scope.setSmallImage = function() {
      return $scope.image.src = 'images/trier.png';
    };
  });

}).call(this);
