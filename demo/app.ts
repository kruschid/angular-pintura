import * as angular from 'angular'
import * as Konva from 'konva'
import {IPinturaConfig} from '../src/ng-directive'

require('./app.sass')
require('../src/ng-directive.ts')

const app = angular.module('app', ['kdPintura'])

app.controller('PinturaCtrl', ($scope) => {
  let config:IPinturaConfig = {
    // src: 'images/img1.jpg' 
    src: require('file-loader!./images/img1.jpg'),
    showHotspots: true,
    hotspots: [
      new Konva.Ellipse({
        x: 100,
        y: 100,
        radius:{x: 50, y: 25},
        fill: 'red',
      })
    ]
  }
  config.hotspots.forEach(element => {
    element.on('click', console.log)
  });
  $scope.config = config

  $scope.setURLSource1 = () =>
    $scope.config.src = require('file-loader!./images/img1.jpg')
  
  $scope.setURLSource2 = () =>
    $scope.config.src = require('file-loader!./images/img2.jpg')
  
  $scope.setSmallImage = () =>
    $scope.config.src = require('file-loader!./images/trier.png')
})