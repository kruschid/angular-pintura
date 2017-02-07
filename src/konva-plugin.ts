// import * as Konva from 'konva'
import * as Konva from 'konva'
import * as angular from 'angular'

export class State {
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
  minScale:number = 1
  maxScale:number = 3
  rotation: number = 0
  tween: Konva.Tween
  tweenDuration = 0.25
  fitImageOnload = true
  zoomStep = 0.1
  mwZoomStep = 0.01

  constructor(private notifier:(state:State)=>void) {
    this.stage.add(this.rootLayer)
    this.rootLayer
      .add(this.image)
      .add(this.hotspotsGroup)
  }

  public notify(){
    this.notifier(this)
  }
}

function fromRelativeScale(state:State, relativeScale:number):number{
  // time = relativeScale, wich is in range of [0,1]
  const t = Math.max(Math.min(relativeScale,1), 0)
  const b = state.minScale
  const c = state.maxScale - state.minScale
  // return -c * (Math.sqrt(1 - t*t) - 1) + b
  return c*t*t+b
}

export function toRelativeScale(state:State):number{
  const b = state.minScale
  const c = state.maxScale - state.minScale
  const s = state.rootLayer.scaleX()
  // return Math.sqrt(Math.pow((s-c-b)/-c,2)+1)
  return Math.sqrt(Math.abs((s-b)/c))
}

export function resize(state:State, s:{width:number, height:number}){
  console.log('State: resizing to', s) 
  state.stage.setSize(s)
  adjustScaleBounds(state)
}

export function changeImage(state:State, src):Promise<any>{
  return loadImage(state,src)
    .then((img)=>{
      state.image.image(img)
      adjustScaleBounds(state)
      if(state.fitImageOnload){
        return fitInView(state)
      }else{
        state.notify()
      }
    })
}

export function fitInView(state:State):Promise<any>{
  return fitInViewTween(state)
    .then(()=> state.notify())
}

export function zoomToCenter(state:State, relativeScale):Promise<any>{
  const scale = fromRelativeScale(state, relativeScale)
  return zoomToCenterTween(state, scale)
    .then(()=> state.notify())
}

export function zoomIn(state:State):Promise<any>{
  const relScale = toRelativeScale(state) + state.zoomStep
  return zoomToCenter(state, relScale)
}

export function zoomOut(state:State):Promise<any>{
  const relScale = toRelativeScale(state) - state.zoomStep
  return zoomToCenter(state, relScale)
}

function loadImage(state:State, src):Promise<any>{ 
  console.log('State: loading image', src)
  return new Promise((resolve)=> {
    const img = new Image()
    img.onload = () => resolve(img)
    img.src = src
  })
}

function adjustScaleBounds(state:State){
  console.log('adjusting scale bounds')
  // lets try by adjusting by width
  let minScale = state.stage.width() / state.image.width()
  // image doesnt fit vertically with the prior adjustment
  if(state.stage.height() < state.image.height()*minScale){
    // then adjust by height
    minScale = state.stage.height() / state.image.height()
  }
  // never scale up original image size
  state.minScale = Math.min(minScale, 1)
}

function zoomToPointAttributes(state: State, scale, point){
  // translate point to local coordinates
  const imgTransform = state.rootLayer.getAbsoluteTransform().copy()
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

function zoomToCenterTween(state: State, scale:number):Promise<any>{
  console.log('zoomToCenterTween', state, scale)
  const center = {
    x: state.stage.width() / 2,
    y: state.stage.height() / 2
  }
  return zoomToPointTween(state, scale, center)
}

function zoomToPointerTween(state: State, relativeScale):Promise<any>{
  console.log('zoomToPointerTween', state, relativeScale)
  const scale = fromRelativeScale(state, relativeScale)
  const point = state.stage.getPointerPosition()
  return zoomToPointTween(state, scale, point)
}

function zoomToPointTween(state: State, scale, point):Promise<any>{
  console.log('zoomToCenterTween: ', state, scale, point)
  return new Promise((resolve)=>{
    console.log('scale:', scale)
    const tweenAttrs = zoomToPointAttributes(state, scale, point)
    // exit when nothing to do (curr state matches the attributes)
    const nothingToDo = ( scale === state.rootLayer.scaleX()
      && tweenAttrs.x === state.rootLayer.x()
      && tweenAttrs.y === state.rootLayer.y() )
    if(!nothingToDo){
      /* 
        freeze state and destroy prior animation
        !!! do not use finish() here, it'll cause adoptation of prior tween state !!
        at least onFinish will be fired because after pause and destroy the tween is getting started again
      */
      if(state.tween){
        state.tween.pause().destroy() 
      }
      state.tween = new Konva.Tween( Object.assign({}, tweenAttrs, {
        node: state.rootLayer,
        duration: state.tweenDuration,
        easing: Konva.Easings.EaseOut,
        onFinish: resolve
      }))
      state.tween.play()
    } // else
  })
}

function fitInViewAttributes(state:State){
  const imgScaled = {
    width: state.image.width()*state.minScale,
    height: state.image.height()*state.minScale
  } // imgScaled
  const attributes = {
    scaleX: state.minScale,
    scaleY: state.minScale,
    x: 0,
    y: 0
  }
  // center image horizontally/vertically 
  if(imgScaled.width < state.stage.width())
    attributes.x = (state.stage.width()-imgScaled.width)/2
  if(imgScaled.height < state.stage.height())
    attributes.y = (state.stage.height()-imgScaled.height)/2
  return attributes
}

function fitInViewTween(state:State):Promise<any> {
  return new Promise((resolve) =>{
    const attrs = fitInViewAttributes(state)
    const nothingToDo = ( attrs.x === state.rootLayer.x()
      && attrs.y === state.rootLayer.y()
      && attrs.scaleX == state.rootLayer.scaleX())
    if(!nothingToDo){
      if(state.tween)
        state.tween.pause().destroy()
      state.tween = new Konva.Tween(Object.assign({}, attrs,{
        node: state.rootLayer,
        duration: state.tweenDuration,
        easing: Konva.Easings.EaseOut,
        onFinish: resolve
      }))
      state.tween.play()
    }
  }) // Promise
} // fitInViewTween
