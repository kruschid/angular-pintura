import * as angular from 'angular'
import {IPinturaConfig} from '../src/ng-directive'

require('./app.sass')
require('../src/ng-directive.ts')

const app = angular.module('app', ['kdPintura'])

app.controller('PinturaCtrl', ($scope) => {
  let config:IPinturaConfig = {
    // src: 'images/img1.jpg' 
    src: require('file-loader!./images/img1.jpg') 
  }
  $scope.config = config

})