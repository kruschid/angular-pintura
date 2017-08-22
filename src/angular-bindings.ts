import * as angular from 'angular'
import * as Konva from 'konva'
import * as KDP from './konva-pintura'

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
  zoomIn()
  zoomOut()
}

const directive = angular.module('kdPintura', [])

directive.directive('kdPintura', ['$window', ($window) => ({
  transclude: true,
  scope:{
    config: '=kdpConfig'
  },
  link: (scope:IPinturaDirectiveScope, element, attrs, ctrl, transcludeFn) => {
    const config:IPinturaConfig = scope.config ? scope.config : {}
    const state = new KDP.State(syncConfig)
    element.append(state.stage.container())
    // share scope with transcluded template
    transcludeFn(scope, (transcludedTemplate) =>
      element.append(transcludedTemplate)
    )

    function syncConfig(state:KDP.State){
      console.log('syncConfig')
      scope.$apply(()=>{
        config.relativeScale = KDP.toRelativeScale(state)
        config.scale = state.rootLayer.scaleX()
      })
    }

    function onResize(){
      KDP.resize(state, {
        width: element[0].clientWidth,
        height: element[0].clientHeight 
      })
    } // onResize

    function changeImage(){
      if(config.src)
        KDP.changeImage(state, config.src)
      else
        console.log('angular-pintura: src should be a url')
    } // changeImage

    function changeRealtiveScale(relativeScale){
      if(typeof relativeScale === 'number')
        KDP.zoomToCenter(state, relativeScale)
    }

    function changeHotspots(){
      if(config.hotspots && config.hotspots.length) {
        state.hotspotsGroup.removeChildren()
        state.hotspotsGroup.add.apply(
          state.hotspotsGroup, 
          config.hotspots
        )
      }
    }

    function changeHotspotsVisbility(){
      state.hotspotsGroup.visible(config.showHotspots)
      state.stage.draw()
    }

    scope.fitInView = () => KDP.fitInView(state)
    scope.zoomIn = () => KDP.zoomIn(state)
    scope.zoomOut = () =>  KDP.zoomOut(state)
    scope.$watch('config.src', changeImage)
    scope.$watch('config.relativeScale', changeRealtiveScale)
    scope.$watch('config.hotspots', changeHotspots)
    scope.$watch('config.showHotspots', changeHotspotsVisbility)
    onResize()
  } 
})])

export const KDPintura = directive