import * as Konva from 'konva';
export class State {
    constructor(notifier) {
        this.notifier = notifier;
        this.stage = new Konva.Stage({
            container: document.createElement('div')
        });
        this.rootLayer = new Konva.Layer({
            draggable: true
        });
        this.hotspotsGroup = new Konva.Group();
        this.image = new Konva.Image({
            image: new Image()
        });
        this.minScale = 1;
        this.maxScale = 3;
        this.rotation = 0;
        this.tweenDuration = 0.25;
        this.fitImageOnload = true;
        this.zoomStep = 0.1;
        this.mwZoomStep = 0.01;
        this.stage.add(this.rootLayer);
        this.rootLayer
            .add(this.image)
            .add(this.hotspotsGroup);
    }
    notify() {
        this.notifier(this);
    }
}
function fromRelativeScale(state, relativeScale) {
    const t = Math.max(Math.min(relativeScale, 1), 0);
    const b = state.minScale;
    const c = state.maxScale - state.minScale;
    return c * t * t + b;
}
export function toRelativeScale(state) {
    const b = state.minScale;
    const c = state.maxScale - state.minScale;
    const s = state.rootLayer.scaleX();
    return Math.sqrt(Math.abs((s - b) / c));
}
export function resize(state, s) {
    console.log('State: resizing to', s);
    state.stage.setSize(s);
    adjustScaleBounds(state);
}
export function changeImage(state, src) {
    return loadImage(state, src)
        .then((img) => {
        state.image.image(img);
        adjustScaleBounds(state);
        if (state.fitImageOnload) {
            return fitInView(state);
        }
        else {
            state.notify();
        }
    });
}
export function fitInView(state) {
    return fitInViewTween(state)
        .then(() => state.notify());
}
export function zoomToCenter(state, relativeScale) {
    const scale = fromRelativeScale(state, relativeScale);
    return zoomToCenterTween(state, scale)
        .then(() => state.notify());
}
export function zoomIn(state) {
    const relScale = toRelativeScale(state) + state.zoomStep;
    return zoomToCenter(state, relScale);
}
export function zoomOut(state) {
    const relScale = toRelativeScale(state) - state.zoomStep;
    return zoomToCenter(state, relScale);
}
function loadImage(state, src) {
    console.log('State: loading image', src);
    return new Promise((resolve) => {
        const img = new Image();
        img.onload = () => resolve(img);
        img.src = src;
    });
}
function adjustScaleBounds(state) {
    console.log('adjusting scale bounds');
    let minScale = state.stage.width() / state.image.width();
    if (state.stage.height() < state.image.height() * minScale) {
        minScale = state.stage.height() / state.image.height();
    }
    state.minScale = Math.min(minScale, 1);
}
function zoomToPointAttributes(state, scale, point) {
    const imgTransform = state.rootLayer.getAbsoluteTransform().copy();
    imgTransform.invert();
    const imgPoint = imgTransform.point(point);
    return {
        x: (-imgPoint.x + point.x / scale) * scale,
        y: (-imgPoint.y + point.y / scale) * scale,
        scaleX: scale,
        scaleY: scale
    };
}
function zoomToCenterTween(state, scale) {
    console.log('zoomToCenterTween', state, scale);
    const center = {
        x: state.stage.width() / 2,
        y: state.stage.height() / 2
    };
    return zoomToPointTween(state, scale, center);
}
function zoomToPointerTween(state, relativeScale) {
    console.log('zoomToPointerTween', state, relativeScale);
    const scale = fromRelativeScale(state, relativeScale);
    const point = state.stage.getPointerPosition();
    return zoomToPointTween(state, scale, point);
}
function zoomToPointTween(state, scale, point) {
    console.log('zoomToCenterTween: ', state, scale, point);
    return new Promise((resolve) => {
        console.log('scale:', scale);
        const tweenAttrs = zoomToPointAttributes(state, scale, point);
        const nothingToDo = (scale === state.rootLayer.scaleX()
            && tweenAttrs.x === state.rootLayer.x()
            && tweenAttrs.y === state.rootLayer.y());
        if (!nothingToDo) {
            if (state.tween) {
                state.tween.pause().destroy();
            }
            state.tween = new Konva.Tween(Object.assign({}, tweenAttrs, {
                node: state.rootLayer,
                duration: state.tweenDuration,
                easing: Konva.Easings.EaseOut,
                onFinish: resolve
            }));
            state.tween.play();
        }
    });
}
function fitInViewAttributes(state) {
    const imgScaled = {
        width: state.image.width() * state.minScale,
        height: state.image.height() * state.minScale
    };
    const attributes = {
        scaleX: state.minScale,
        scaleY: state.minScale,
        x: 0,
        y: 0
    };
    if (imgScaled.width < state.stage.width())
        attributes.x = (state.stage.width() - imgScaled.width) / 2;
    if (imgScaled.height < state.stage.height())
        attributes.y = (state.stage.height() - imgScaled.height) / 2;
    return attributes;
}
function fitInViewTween(state) {
    return new Promise((resolve) => {
        const attrs = fitInViewAttributes(state);
        const nothingToDo = (attrs.x === state.rootLayer.x()
            && attrs.y === state.rootLayer.y()
            && attrs.scaleX == state.rootLayer.scaleX());
        if (!nothingToDo) {
            if (state.tween)
                state.tween.pause().destroy();
            state.tween = new Konva.Tween(Object.assign({}, attrs, {
                node: state.rootLayer,
                duration: state.tweenDuration,
                easing: Konva.Easings.EaseOut,
                onFinish: resolve
            }));
            state.tween.play();
        }
    });
}
