import * as angular from 'angular'
import * as Konva from 'konva'
import {NGPCanvas} from './konva-plugin'

const directive = angular.module('kdPintura', [])

directive.directive('kdPintura', ($window) => ({
  transclude: true,
  scope:{
    config: '=ngpConfig'
  },
  link: class PinturaDirective{
    private canvas: NGPCanvas
    private src:string
    private scaling:number
    private position:{x:number, y:number}
    private fitOnload:boolean
    private maxScaling:number
    private scaleStep:number
    private mwScaleStep: number
    private showIndicator: number
    private moveStep: number
    private progress: number
    private hotspots: Konva.Shape[]

    constructor(scope, element, attrs, ctrl, transcludeFn){
      // append konva container to directive
      this.canvas = new NGPCanvas()
      element.append(this.canvas.stage.container())
      // share scope with transcluded template
      transcludeFn(scope, (transcludedTemplate)=>
        element.append(transcludedTemplate)
      )
    }
  }
}))

export const KDPintura = directive