import * as angular from 'angular'
import * as Konva from 'konva'
import * as NGP from './konva-plugin'

export interface IPinturaConfig{
  src?: string
  relativeScale?: number
  scale?: number
  position?: {x:number, y:number}
  fitOnload?: boolean
  maxScale?: number
  scaleStep?: number
  mwScaleStep?: number
  showIndicator?: number
  moveStep?: number
  progress?: number
  hotspots?: Konva.Shape[]
}

interface IPinturaDirectiveScope extends angular.IScope{
  config: IPinturaConfig
}

const directive = angular.module('kdPintura', [])

directive.directive('kdPintura', ($window) => ({
  transclude: true,
  scope:{
    config: '=kdpConfig'
  },
  link: (scope:IPinturaDirectiveScope, element, attrs, ctrl, transcludeFn) => {
    const config:IPinturaConfig = scope.config ? scope.config : {}
    const canvas = new NGP.Canvas()
    element.append(canvas.stage.container())
    // share scope with transcluded template
    transcludeFn(scope, (transcludedTemplate) =>
      element.append(transcludedTemplate)
    )

    function onResize(){
      canvas.resize({
        width: element[0].clientWidth,
        height: element[0].clientHeight 
      })
    } // onResize

    function changeImage(){
      if(config.src)
        NGP.changeImage(canvas, config.src)
    }

    function changeRealtiveScale(){
      if(typeof config.relativeScale === 'number')
        NGP.zoomToCenterTween(canvas, config.relativeScale)
    }

    scope.$watch('config.src', changeImage)
    scope.$watch('config.relativeScale', changeRealtiveScale)
    onResize()
  } 
}))

export const KDPintura = directive