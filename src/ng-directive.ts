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
  showHotspots?: boolean
}

interface IPinturaDirectiveScope extends angular.IScope{
  config: IPinturaConfig
  fitInView()
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

    function syncConfig(){
      console.log('syncConfig')
      scope.$apply(()=>{
        config.relativeScale = NGP.toRelativeScale(canvas)
        console.log(config.relativeScale)
        
      })
    }

    function onResize(){
      canvas.resize({
        width: element[0].clientWidth,
        height: element[0].clientHeight 
      })
    } // onResize

    function changeImage(){
      if(config.src)
        NGP.changeImage(canvas, config.src)
        .then(fitInView)
    } // changeImage

    function fitInView(){
        NGP.fitInViewTween(canvas)
        .then(syncConfig)
    }

    function changeRealtiveScale(){
      if(typeof config.relativeScale === 'number')
        NGP.zoomToCenterTween(canvas, config.relativeScale)
    }

    function changeHotspots(){
      if(config.hotspots)
        canvas.hotspotsGroup.removeChildren()
        canvas.hotspotsGroup.add.apply(
          canvas.hotspotsGroup, 
          config.hotspots
        )
    }

    function changeHotspotsVisbility(){
      canvas.hotspotsGroup.visible(config.showHotspots)
      canvas.stage.draw()
    }

    scope.fitInView = fitInView
    scope.$watch('config.src', changeImage)
    scope.$watch('config.relativeScale', changeRealtiveScale)
    scope.$watch('config.hotspots', changeHotspots)
    scope.$watch('config.showHotspots', changeHotspotsVisbility)
    onResize()
  } 
}))

export const KDPintura = directive