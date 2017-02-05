// import * as Konva from 'konva'
import * as Konva from 'konva'
import * as angular from 'angular'

export class NGPCanvas {
  stage: Konva.Stage
  rootLayer: Konva.Layer
  imageLayer: Konva.Layer
  hotspotsGroup: Konva.Group
  image: Konva.Image
  progressCb: Function

  constructor() {
    this.stage = new Konva.Stage({
      container: angular.element('<div>')[0]
    })
    this.rootLayer = new Konva.Layer()
    this.imageLayer = new Konva.Layer()
    this.hotspotsGroup = new Konva.Group()
    this.image = new Konva.Image({
      image: <HTMLImageElement>angular.element('<img>')[0]
    })
  }
}