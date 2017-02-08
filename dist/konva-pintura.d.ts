import * as Konva from 'konva';
export declare class State {
    private notifier;
    stage: Konva.Stage;
    rootLayer: Konva.Layer;
    hotspotsGroup: Konva.Group;
    image: Konva.Image;
    isLoading: boolean;
    minScale: number;
    maxScale: number;
    rotation: number;
    tween: Konva.Tween;
    tweenDuration: number;
    fitImageOnload: boolean;
    zoomStep: number;
    mwZoomStep: number;
    constructor(notifier: (state: State) => void);
    notify(): void;
}
export declare function toRelativeScale(state: State): number;
export declare function resize(state: State, s: {
    width: number;
    height: number;
}): void;
export declare function changeImage(state: State, src: any): Promise<any>;
export declare function fitInView(state: State): Promise<any>;
export declare function zoomToCenter(state: State, relativeScale: any): Promise<any>;
export declare function zoomIn(state: State): Promise<any>;
export declare function zoomOut(state: State): Promise<any>;
