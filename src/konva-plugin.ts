// import * as Konva from 'konva'
import * as Konva from 'konva'
import * as angular from 'angular'

export class Canvas {
  stage = new Konva.Stage({
    container: document.createElement('div')
  })
  rootLayer= new Konva.Layer({
    draggable: true
  })
  hotspotsGroup = new Konva.Group()
  image= new Konva.Image({
    image: new Image()
  })
  isLoading: boolean
  minScale = 1
  maxScale = 5
  relativeScale: number // 0 to 1
  rotation: number
  tween: Konva.Tween
  tweenDuration: number = 0.25

  constructor(private debug:boolean = true) {
    this.stage.add(this.rootLayer)
    this.rootLayer
      .add(this.image)
      .add(this.hotspotsGroup)
  }

  public resize(s:{width:number, height:number}){
    console.log('Canvas: resizing to', s)   
    this.stage.setSize(s)
    // adjust scale bounds
  }
}

function resize(canvas:Canvas, s:{width:number, height:number}){
  console.log('Canvas: resizing to', s) 
  canvas.stage.setSize(s)
}

export function changeImage(canvas:Canvas, src){
  loadImage(canvas,src).then((img)=>{
    canvas.image.image(img)
    adjustScaleBounds(canvas)
    // fit in view
  })
}

function loadImage(canvas:Canvas, src):Promise<any>{ 
  console.log('Canvas: loading image', src)
  return new Promise((resolve)=> {
    const img = new Image()
    img.onload = () => resolve(img)
    img.src = src
  })
}

function adjustScaleBounds(canvas:Canvas){
  console.log('adjusting scale bounds')
  // lets try by adjusting by width
  let minScale = canvas.stage.width() / canvas.image.width()
  // image doesnt fit vertically with the prior adjustment
  if(canvas.stage.height() < canvas.image.height()*minScale){
    // then adjust by height
    minScale = canvas.stage.height() / canvas.image.height()
  }
  // never scale up original image size
  canvas.minScale = Math.min(minScale, 1)
}

function zoomToPointAttributes(canvas: Canvas, scale, point){
  // translate point to local coordinates
  const imgTransform = canvas.rootLayer.getAbsoluteTransform().copy()
  imgTransform.invert()
  const imgPoint = imgTransform.point(point) 
  // 
  return {
    x: (-imgPoint.x + point.x / scale)*scale,
    y: (-imgPoint.y + point.y / scale)*scale,
    scaleX: scale,
    scaleY: scale
  }
}

export function zoomToCenterTween(canvas: Canvas, relativeScale):Promise<any>{
  console.log('zoomToCenterTween', canvas, relativeScale)
  const center = {
    x: canvas.stage.width() / 2,
    y: canvas.stage.height() / 2
  }
  const scale = fromRelativeScale(canvas, relativeScale)
  return zoomToPointTween(canvas, scale, center)
}

export function zoomToPointerTween(canvas: Canvas, relativeScale):Promise<any>{
  console.log('zoomToPointerTween', canvas, relativeScale)
  const scale = fromRelativeScale(canvas, relativeScale)
  const point = canvas.stage.getPointerPosition()
  return zoomToPointTween(canvas, scale, point)
}

function zoomToPointTween(canvas: Canvas, scale, point):Promise<any>{
  console.log('zoomToCenterTween: ', canvas, scale, point)
  return new Promise((resolve, reject)=>{
    console.log('scale:', scale)
    const tweenAttrs = zoomToPointAttributes(canvas, scale, point)
    // exit when nothing to do (curr state matches the attributes)
    const nothingToDo = ( scale === canvas.rootLayer.scaleX()
      || tweenAttrs.x === canvas.rootLayer.x()
      || tweenAttrs.y === canvas.rootLayer.y() )
    if(nothingToDo){
      reject()
    } // if
    else{
      /* 
        freeze state and destroy prior animation
        !!! do not use finish() here, it'll cause adoptation of prior tween state !!
        at least onFinish will be fired because after pause and destroy the tween is getting started again
      */
      if(canvas.tween){
        canvas.tween.pause().destroy() 
      }
      canvas.tween = new Konva.Tween( Object.assign({}, tweenAttrs, {
        node: canvas.rootLayer,
        duration: canvas.tweenDuration,
        easing: Konva.Easings.EaseOut,
        onFinish: resolve
      }))
      canvas.tween.play()
    } // else
  })
}

function fromRelativeScale(canvas:Canvas, relativeScale:number):number{
  // time = relativeScale, with is in range of [0,1]
  const t = relativeScale
  const b = canvas.minScale
  const c = canvas.maxScale
  //console.log('fromRelativeScale:',canvas.maxScale*t + canvas.minScale);
  return -c * (Math.sqrt(1 - t*t) - 1) + b
  // quartic easing in
  // return canvas.maxScale*t*t + canvas.minScale
}