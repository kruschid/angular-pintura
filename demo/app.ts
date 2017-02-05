import * as angular from 'angular'

require('./app.sass')
require('../src/ng-directive.ts')

const app = angular.module('app', ['kdPintura'])

app.controller('PinturaCtrl', class PinturaCtlr{
  
})